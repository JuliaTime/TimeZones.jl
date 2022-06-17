struct TZJTransition
    utc_offset::Int32  # Resolution in seconds
    dst_offset::Int16  # Resolution in seconds
    designation_index::UInt8
end

read(io::IO, name::AbstractString) = read(io)(name)

function read(io::IO)
    magic = Base.read(io, 4)  # Read the 4 byte magic identifier
    @assert magic == b"TZjf" "Magic file identifier \"TZjf\" not found."

    version = Int(Base.read(io, UInt8))
    return _read(io, Val(version))
end

function _read(io::IO, version::Val{1})
    tzh_timecnt = ntoh(Base.read(io, Int32))  # Number of transition dates
    tzh_typecnt = ntoh(Base.read(io, Int32))  # Number of transition types (must be > 0)
    tzh_charcnt = ntoh(Base.read(io, Int32))  # Number of time zone abbreviation characters
    class = Class(ntoh(Base.read(io, UInt8)))

    transition_times = Vector{Int64}(undef, tzh_timecnt)
    for i in eachindex(transition_times)
        transition_times[i] = ntoh(Base.read(io, Int64))
    end
    cutoff_time = ntoh(Base.read(io, Int64))

    lindexes = Vector{UInt8}(undef, tzh_timecnt)
    for i in eachindex(lindexes)
        lindexes[i] = ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
    end

    tzj_transitions = Vector{TZJTransition}(undef, tzh_typecnt)
    for i in eachindex(tzj_transitions)
        tzj_transitions[i] = TZJTransition(
            ntoh(Base.read(io, Int32)),
            ntoh(Base.read(io, Int16)),
            ntoh(Base.read(io, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    abbrs = Vector{UInt8}(undef, tzh_charcnt)
    for i in eachindex(abbrs)
        abbrs[i] = ntoh(Base.read(io, UInt8))
    end

    # Now build the time zone transitions
    constructor = if tzh_timecnt == 0 || (tzh_timecnt == 1 && tzj_transitions[1] == TIMESTAMP_MIN)
        t = tzj_transitions[1]
        name -> (FixedTimeZone(name, t.utc_offset, t.dst_offset), class)
    else
        transitions = Transition[]
        cutoff = timestamp2datetime(cutoff_time, nothing)

        prev_zone = nothing
        for i in eachindex(transition_times)
            timestamp = transition_times[i]
            t = tzj_transitions[lindexes[i]]

            # Sometimes tzfiles save on storage by having multiple names in one for example:
            # "WSST\0" at index 1 turns into "WSST" where as index 2 results in "SST"
            # for "Pacific/Apia".
            abbr = abbreviation(abbrs, t.designation_index)
            zone = FixedTimeZone(abbr, t.utc_offset, t.dst_offset)

            if zone != prev_zone
                utc_datetime = timestamp2datetime(timestamp, typemin(DateTime))
                push!(transitions, Transition(utc_datetime, zone))
            end

            prev_zone = zone
        end

        name -> (VariableTimeZone(name, transitions, cutoff), class)
    end

    return constructor
end
