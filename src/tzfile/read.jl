# Parsing tzfiles references:
# - https://man7.org/linux/man-pages/man5/tzfile.5.html
# - ftp://ftp.iana.org/tz/code/tzfile.5.txt

const TZFILE_CUTOFF = unix2datetime(typemax(Int32))

# Minimum timestamps used in the tzfile format. Typically represents negative infinity.
transition_min(::Type{Int64}) = -576460752303423488  # -2^59
transition_min(::Type{Int32}) = Int32(-2147483648)   # -2^31

struct TransitionTimeInfo
    gmtoff::Int32     # tt_gmtoff
    isdst::Int8       # tt_isdst
    abbrindex::UInt8  # tt_abbrind
end

function abbreviation(chars::AbstractVector{UInt8}, index::Integer=1)
    return unsafe_string(pointer(chars, index))
end

"""
    TZFile.read(io::IO, name::AbstractString) -> TimeZone

Read the content of an I/O stream and process it as a
[POSIX tzfile](https://man7.org/linux/man-pages/man5/tzfile.5.html). The returned
`TimeZone` will be given the supplied name `name` unless a `FixedTimeZone` is returned.
"""
function read(io::IO, name::AbstractString)
    # For compatibility reasons the tzfile will always start with version '\0' data.
    version, tz = _read(io, name, '\0')

    # The higher precision data in version 2 and 3 formats occurs after the initial
    # compatibility data.
    if version != '\0'
        version, tz = _read(io, name, version)
    end

    return tz
end

function _read(io::IO, name::AbstractString, force_version::Char='\0')
    magic = Base.read(io, 4)  # Read the 4 byte magic identifier
    @assert magic == b"TZif" "Magic file identifier \"TZif\" not found."

    # A byte indicating the version of the file's format: '\0', '2', '3'
    version = Char(Base.read(io, UInt8))
    Base.read(io, 15)  # Fifteen bytes reserved for future use

    tzh_ttisgmtcnt = ntoh(Base.read(io, Int32))  # Number of UTC/local indicators
    tzh_ttisstdcnt = ntoh(Base.read(io, Int32))  # Number of standard/wall indicators
    tzh_leapcnt = ntoh(Base.read(io, Int32))  # Number of leap seconds
    tzh_timecnt = ntoh(Base.read(io, Int32))  # Number of transition dates
    tzh_typecnt = ntoh(Base.read(io, Int32))  # Number of TransitionTimeInfos (must be > 0)
    tzh_charcnt = ntoh(Base.read(io, Int32))  # Number of time zone abbreviation characters

    time_type = force_version == '\0' ? Int32 : Int64
    transition_time_min = transition_min(time_type)

    transition_times = Vector{time_type}(undef, tzh_timecnt)
    for i in eachindex(transition_times)
        transition_times[i] = ntoh(Base.read(io, time_type))
    end
    lindexes = Vector{UInt8}(undef, tzh_timecnt)
    for i in eachindex(lindexes)
        lindexes[i] = ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
    end
    ttinfo = Vector{TransitionTimeInfo}(undef, tzh_typecnt)
    for i in eachindex(ttinfo)
        ttinfo[i] = TransitionTimeInfo(
            ntoh(Base.read(io, Int32)),
            ntoh(Base.read(io, Int8)),
            ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    abbrs = Vector{UInt8}(undef, tzh_charcnt)
    for i in eachindex(abbrs)
        abbrs[i] = ntoh(Base.read(io, UInt8))
    end

    # leap seconds (unused)
    leapseconds_time = Vector{time_type}(undef, tzh_leapcnt)
    leapseconds_seconds = Vector{Int32}(undef, tzh_leapcnt)
    for i in eachindex(leapseconds_time)
        leapseconds_time[i] = ntoh(Base.read(io, time_type))
        leapseconds_seconds[i] = ntoh(Base.read(io, Int32))
    end

    # standard/wall and UTC/local indicators (unused)
    isstd = Vector{Int8}(undef, tzh_ttisstdcnt)
    for i in eachindex(isstd)
        isstd[i] = ntoh(Base.read(io, Int8))
    end
    isgmt = Vector{Int8}(undef, tzh_ttisgmtcnt)
    for i in eachindex(isgmt)
        isgmt[i] = ntoh(Base.read(io, Int8))
    end

    # POSIX TZ variable string used for transistions after the last ttinfo (unused)
    if force_version != '\0'
        readline(io)
        posix_tz_str = chomp(readline(io))
    end

    # Now build the time zone transitions
    if tzh_timecnt == 0 || (tzh_timecnt == 1 && transition_times[1] == transition_time_min)
        timezone = FixedTimeZone(name, ttinfo[1].gmtoff)
    else
        # Calculate transition info
        transitions = Transition[]
        utc = dst = 0
        for i in eachindex(transition_times)
            info = ttinfo[lindexes[i]]

            # Since the tzfile does not contain the DST offset we need to
            # attempt to calculate it.
            if info.isdst == 0
                utc = info.gmtoff
                dst = 0
            elseif dst == 0
                # isdst == false and the last DST offset was 0:
                # assume that only the DST offset has changed
                dst = info.gmtoff - utc
            else
                # isdst == false and the last DST offset was not 0:
                # assume that only the GMT offset has changed
                utc = info.gmtoff - dst
            end

            # Sometimes tzfiles save on storage by having multiple names in one for example:
            # "WSST\0" at index 1 turns into "WSST" where as index 2 results in "SST"
            # for "Pacific/Apia".
            abbr = abbreviation(abbrs, info.abbrindex)
            tz = FixedTimeZone(abbr, utc, dst)

            if isempty(transitions) || last(transitions).zone != tz
                if transition_times[i] == transition_time_min
                    utc_datetime = typemin(DateTime)
                else
                    utc_datetime = unix2datetime(Int64(transition_times[i]))
                end

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

        timezone = VariableTimeZone(name, transitions, cutoff)
    end

    return version, timezone
end
