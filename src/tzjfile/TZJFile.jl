module TZJFile

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: Class, FixedTimeZone, Transition, VariableTimeZone, iscomposite, isdst
using ...TimeZones.TZFile: transition_min, assemble_designations, DATETIME_EPOCH, abbreviation

const DEFAULT_VERSION = 1
const TIMESTAMP_MIN = transition_min(Int64)

function datetime2timestamp(x, sentinel)
    return x != sentinel ? convert(Int64, datetime2unix(x)) : TIMESTAMP_MIN
end

function timestamp2datetime(x::Int64, sentinel)
    return x != TIMESTAMP_MIN ? unix2datetime(x) : sentinel
end



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

function _write(
    io::IO,
    version::Val{1};
    class::UInt8,
    transition_times::Vector{Int64},
    tzj_transitions::Vector{TZJTransition},
    cutoff::Int64,
    assembled_designations::AbstractString,
)
    # iscomposite(class) && error("Class of a time zone should be a single bit: $class")

    # TODO: Interface needs more thought. Definitely do need a index which maps the unique
    # `transition_time_infos` to each transition_time
    if length(transition_times) > 0
        unique_tzj_transitions = unique(tzj_transitions)
        tzj_transition_indices = indexin(tzj_transitions, unique_tzj_transitions)
        tzj_transitions = unique_tzj_transitions

        @assert length(transition_times) == length(tzj_transition_indices)
    else
        tzj_transition_indices = Vector{Int}()
        tzj_transitions = unique(tzj_transitions)
    end

    Base.write(io, b"TZjf")  # Magic four-byte ASCII sequence
    Base.write(io, 0x01)  # Single-byte identifying the tzfile version

    # Six four-byte integer values
    Base.write(io, hton(Int32(length(transition_times))))           # tzh_timecnt
    Base.write(io, hton(Int32(length(tzj_transitions)))) # tzh_typecnt
    Base.write(io, hton(Int32(length(assembled_designations))))   # tzh_charcnt
    Base.write(io, hton(class))

    # Transition time and leap second time byte size
    T = Int64

    # TODO: Sorting provides us a way to avoid checking on each loop
    for timestamp in transition_times

        # Convert timestamps of `typemin(DateTime)` to the `timestamp_min`
        if timestamp == DATETIME_EPOCH
            timestamp = TIMESTAMP_MIN
        end

        Base.write(io, hton(timestamp))
    end
    Base.write(io, hton(cutoff))

    for index in tzj_transition_indices
        Base.write(io, hton(UInt8(index - 1)))  # Convert 1-indexing to 0-indexing
    end

    # tzh_typecnt ttinfo entries
    for t in tzj_transitions
        Base.write(io, hton(Int32(t.utc_offset)))
        Base.write(io, hton(Int16(t.dst_offset)))
        Base.write(io, hton(UInt8(t.designation_index - 1)))
    end

    for char in assembled_designations
        Base.write(io, hton(UInt8(char)))
    end

    return nothing
end

function write(io::IO, tz::VariableTimeZone; class::Class, version::Integer=DEFAULT_VERSION)
    assembled_designations, designation_indices = assemble_designations(t.zone.name for t in tz.transitions)

    # TODO: Sorting provides us a way to avoid checking for the sentinel on each loop
    transition_times = map(tz.transitions) do t
        datetime2timestamp(t.utc_datetime, typemin(DateTime))
    end

    tzj_transitions = map(enumerate(tz.transitions)) do (i, t)
        TZJTransition(
            Dates.value(Second(t.zone.offset.std)),
            Dates.value(Second(t.zone.offset.dst)),
            designation_indices[i]
        )
    end

    cutoff = datetime2timestamp(tz.cutoff, nothing)

    _write(io, Val(Int(version)); class=class.val, transition_times, tzj_transitions, cutoff, assembled_designations)
end

function write(io::IO, tz::FixedTimeZone; class::Class, version::Integer=DEFAULT_VERSION)
    assembled_designations, designation_indices = assemble_designations([tz.name])

    transition_times = Vector{Int64}()

    tzj_transitions = [
        TZJTransition(
            Dates.value(Second(tz.offset.std)),
            Dates.value(Second(tz.offset.dst)),
            designation_indices[1],
        )
    ]

    cutoff = datetime2timestamp(nothing, nothing)

    _write(io, Val(Int(version)); class=class.val, transition_times, tzj_transitions, cutoff, assembled_designations)
end

end
