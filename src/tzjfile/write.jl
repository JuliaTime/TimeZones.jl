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
