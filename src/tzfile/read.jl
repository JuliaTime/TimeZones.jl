const TZFILE_CUTOFF = unix2datetime(typemax(Int32))

struct TransitionTimeInfo
    ut_offset::Int32          # tt_utoff
    is_dst::UInt8             # tt_isdst
    designation_index::UInt8  # tt_desigidx
end

function get_designation(chars::AbstractVector{UInt8}, index::Integer=1)
    return unsafe_string(pointer(chars, index))
end

"""
    TZFile.read(io::IO) -> Function

Read the content of an I/O stream as a
[POSIX tzfile](https://data.iana.org/time-zones/data/tzfile.5.txt) to produce a `TimeZone`.
As the tzfile format does not include the name of the interpreted time zone this function
returns a closure which takes the single argument `name::AbstractString` and when called
produces a `TimeZone` instance.
"""
function read(io::IO)
    # For compatibility reasons the tzfile will always start with version '\0' content.
    read_signature(io)
    version = read_version(io)
    tz_constructor = read_content(io; version='\0')

    # The higher precision data in version 2 and 3 formats occurs after the initial
    # compatibility data.
    if version != '\0'
        read_signature(io)
        read_version(io)
        tz_constructor = read_content(io; version)
    end

    return tz_constructor
end

function read_signature(io::IO)
    magic = Base.read(io, 4)  # Read the 4 byte magic identifier
    magic == b"TZif" || throw(ArgumentError("Magic file identifier \"TZif\" not found."))
    return magic
end

function read_version(io::IO)
    # A byte indicating the version of the file's format
    version = Char(Base.read(io, UInt8))
    if !(version in SUPPORTED_VERSIONS)
        throw(ArgumentError("Unrecognized tzfile version: '$version'"))
    end
    return version
end

function read_content(io::IO; version::Char)
    # In version '2' and beyond each transition time or leap second time uses
    # 8-bytes instead of 4-bytes.
    T = version == '\0' ? Int32 : Int64

    Base.read(io, 15)  # Fifteen bytes reserved for future use

    tzh_ttisutcnt = ntoh(Base.read(io, Int32))  # Number of UT/local indicators
    tzh_ttisstdcnt = ntoh(Base.read(io, Int32))  # Number of standard/wall indicators
    tzh_leapcnt = ntoh(Base.read(io, Int32))  # Number of leap seconds
    tzh_timecnt = ntoh(Base.read(io, Int32))  # Number of transition dates
    tzh_typecnt = ntoh(Base.read(io, Int32))  # Number of TransitionTimeInfos (must be > 0)
    tzh_charcnt = ntoh(Base.read(io, Int32))  # Number of time zone designation characters

    transition_times = Vector{T}(undef, tzh_timecnt)
    for i in eachindex(transition_times)
        transition_times[i] = ntoh(Base.read(io, T))
    end
    transition_indices = Vector{UInt8}(undef, tzh_timecnt)
    for i in eachindex(transition_indices)
        transition_indices[i] = ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
    end
    transition_types = Vector{TransitionTimeInfo}(undef, tzh_typecnt)
    for i in eachindex(transition_types)
        transition_types[i] = TransitionTimeInfo(
            ntoh(Base.read(io, Int32)),
            ntoh(Base.read(io, Int8)),
            ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    combined_designations = Vector{UInt8}(undef, tzh_charcnt)
    for i in eachindex(combined_designations)
        combined_designations[i] = ntoh(Base.read(io, UInt8))
    end

    # leap seconds (unused)
    leapseconds_time = Vector{T}(undef, tzh_leapcnt)
    leapseconds_seconds = Vector{Int32}(undef, tzh_leapcnt)
    for i in eachindex(leapseconds_time)
        leapseconds_time[i] = ntoh(Base.read(io, T))
        leapseconds_seconds[i] = ntoh(Base.read(io, Int32))
    end

    # standard/wall and UTC/local indicators (unused)
    is_std = Vector{Int8}(undef, tzh_ttisstdcnt)
    for i in eachindex(is_std)
        is_std[i] = ntoh(Base.read(io, Int8))
    end
    is_ut = Vector{Int8}(undef, tzh_ttisutcnt)
    for i in eachindex(is_ut)
        is_ut[i] = ntoh(Base.read(io, Int8))
    end

    # POSIX TZ variable string used for transistions after the last ttinfo (unused)
    if version != '\0'
        readline(io)
        posix_tz_str = chomp(readline(io))
    end

    # Now build the time zone transitions
    tz_constructor = if tzh_timecnt == 0 || (tzh_timecnt == 1 && transition_times[1] == timestamp_min(T))
        name -> FixedTimeZone(name, transition_types[1].ut_offset)
    else
        # Calculate transition info
        transitions = sizehint!(Transition[], tzh_timecnt)
        utc = dst = 0
        for i in eachindex(transition_times)
            ttinfo = transition_types[transition_indices[i]]

            # Since the tzfile does not contain the DST offset we need to
            # attempt to calculate it.
            if ttinfo.is_dst == 0
                utc = ttinfo.ut_offset
                dst = 0
            elseif dst == 0
                # `is_dst == false` and the last DST offset was zero:
                # assume that only the DST offset has changed
                dst = ttinfo.ut_offset - utc
            else
                # `isdst == false` and the last DST offset was not zero:
                # assume that only the GMT offset has changed
                utc = ttinfo.ut_offset - dst
            end

            # Sometimes tzfiles save on storage by having multiple names in one for example:
            # "WSST\0" at index 1 turns into "WSST" where as index 2 results in "SST"
            # for "Pacific/Apia".
            name = get_designation(combined_designations, ttinfo.designation_index)
            tz = FixedTimeZone(name, utc, dst)

            if isempty(transitions) || last(transitions).zone != tz
                utc_datetime = timestamp2datetime(transition_times[i])
                push!(transitions, Transition(utc_datetime, tz))
            end
        end

        # tzfile's only seem to calculate transitions up to `TZFILE_CUTOFF` even with
        # version that use 64-bit values. Using this value as a heuristic we can set a
        # appropriate cutoff for time zones that should probably have one.
        #
        # Note: that without knowing that additional transitions do exist beyond the last
        # stored transition we cannot determine with perfect accuracy what the cutoff should
        # be.
        cutoff = nothing
        if DateTime(2037) <= last(transitions).utc_datetime < TZFILE_CUTOFF
            cutoff = TZFILE_CUTOFF
        end

        name -> VariableTimeZone(name, transitions, cutoff)
    end

    return tz_constructor
end
