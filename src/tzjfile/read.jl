struct TZJTransition
    utc_offset::Int32  # Resolution in seconds
    dst_offset::Int16  # Resolution in seconds
    designation_index::UInt8
end

function read(io::IO)
    read_signature(io)
    version = read_version(io)
    return read_content(io, Val(version))
end

function read_signature(io::IO)
    magic = Base.read(io, 4)  # Read the 4 byte magic identifier
    magic == b"TZjf" || throw(ArgumentError("Magic file identifier \"TZjf\" not found."))
    return magic
end

read_version(io::IO) = Int(ntoh(Base.read(io, UInt8)))

function read_content(io::IO, version::Val{1})
    tzh_timecnt = ntoh(Base.read(io, Int32))  # Number of transition dates
    tzh_typecnt = ntoh(Base.read(io, Int32))  # Number of transition types (must be > 0)
    tzh_charcnt = ntoh(Base.read(io, Int32))  # Number of time zone designation characters
    class = Class(ntoh(Base.read(io, UInt8)))

    transition_times = Vector{Int64}(undef, tzh_timecnt)
    for i in eachindex(transition_times)
        transition_times[i] = ntoh(Base.read(io, Int64))
    end
    cutoff_time = ntoh(Base.read(io, Int64))

    transition_indices = Vector{UInt8}(undef, tzh_timecnt)
    for i in eachindex(transition_indices)
        transition_indices[i] = ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
    end

    transition_types = Vector{TZJTransition}(undef, tzh_typecnt)
    for i in eachindex(transition_types)
        transition_types[i] = TZJTransition(
            ntoh(Base.read(io, Int32)),
            ntoh(Base.read(io, Int16)),
            ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    combined_designations = Vector{UInt8}(undef, tzh_charcnt)
    for i in eachindex(combined_designations)
        combined_designations[i] = ntoh(Base.read(io, UInt8))
    end

    # Now build the time zone transitions
    tz_constructor = if tzh_timecnt == 0 || (tzh_timecnt == 1 && transition_types[1] == TIMESTAMP_MIN)
        tzj_info = transition_types[1]
        name -> (FixedTimeZone(name, tzj_info.utc_offset, tzj_info.dst_offset), class)
    else
        transitions = Transition[]
        cutoff = timestamp2datetime(cutoff_time, nothing)

        prev_zone = nothing
        for i in eachindex(transition_times)
            timestamp = transition_times[i]
            tzj_info = transition_types[transition_indices[i]]

            # Sometimes tzfiles save on storage by having multiple names in one for example:
            # "WSST\0" at index 1 turns into "WSST" where as index 2 results in "SST"
            # for "Pacific/Apia".
            name = get_designation(combined_designations, tzj_info.designation_index)
            zone = FixedTimeZone(name, tzj_info.utc_offset, tzj_info.dst_offset)

            if zone != prev_zone
                utc_datetime = timestamp2datetime(timestamp, typemin(DateTime))
                push!(transitions, Transition(utc_datetime, zone))
            end

            prev_zone = zone
        end

        name -> (VariableTimeZone(name, transitions, cutoff), class)
    end

    return tz_constructor
end
