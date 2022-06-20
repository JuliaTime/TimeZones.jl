function write(io::IO, tz::VariableTimeZone; class::Class, version::Integer=DEFAULT_VERSION)
    combined_designation, designation_indices = combine_designations(t.zone.name for t in tz.transitions)

    # TODO: Sorting provides us a way to avoid checking for the sentinel on each loop
    transition_times = map(tz.transitions) do t
        datetime2timestamp(t.utc_datetime, typemin(DateTime))
    end
    transition_types = map(enumerate(tz.transitions)) do (i, t)
        TZJTransition(
            Dates.value(Second(t.zone.offset.std)),
            Dates.value(Second(t.zone.offset.dst)),
            designation_indices[i]
        )
    end

    cutoff = datetime2timestamp(tz.cutoff, nothing)

    write_signature(io)
    write_version(io; version)
    write_content(
        io,
        version;
        class=class.val,
        transition_times,
        transition_types,
        cutoff,
        combined_designation,
    )
end

function write(io::IO, tz::FixedTimeZone; class::Class, version::Integer=DEFAULT_VERSION)
    combined_designation, designation_indices = combine_designations([tz.name])

    transition_times = Vector{Int64}()

    transition_types = [
        TZJTransition(
            Dates.value(Second(tz.offset.std)),
            Dates.value(Second(tz.offset.dst)),
            designation_indices[1],
        )
    ]

    cutoff = datetime2timestamp(nothing, nothing)

    write_signature(io)
    write_version(io; version)
    write_content(
        io,
        version;
        class=class.val,
        transition_times,
        transition_types,
        cutoff,
        combined_designation,
    )
end

write_signature(io::IO) = Base.write(io, b"TZjf")
write_version(io::IO; version::Integer) = Base.write(io, hton(UInt8(version)))

function write_content(io::IO, version::Integer; kwargs...)
    return write_content(io, Val(Int(version)); kwargs...)
end

function write_content(
    io::IO,
    version::Val{1};
    class::UInt8,
    transition_times::Vector{Int64},
    transition_types::Vector{TZJTransition},
    cutoff::Int64,
    combined_designation::AbstractString,
)
    if length(transition_times) > 0
        unique_transition_types = unique(transition_types)
        transition_indices = indexin(transition_types, unique_transition_types)
        transition_types = unique_transition_types

        @assert length(transition_times) == length(transition_indices)
    else
        transition_indices = Vector{Int}()
        transition_types = unique(transition_types)
    end

    # Three four-byte integer values
    Base.write(io, hton(Int32(length(transition_times))))      # tzh_timecnt
    Base.write(io, hton(Int32(length(transition_types))))      # tzh_typecnt
    Base.write(io, hton(Int32(length(combined_designation))))  # tzh_charcnt
    Base.write(io, hton(class))

    for timestamp in transition_times
        Base.write(io, hton(timestamp))
    end
    Base.write(io, hton(cutoff))

    for index in transition_indices
        Base.write(io, hton(UInt8(index - 1)))  # Convert 1-indexing to 0-indexing
    end

    # tzh_typecnt ttinfo entries
    for tzj_info in transition_types
        Base.write(io, hton(Int32(tzj_info.utc_offset)))
        Base.write(io, hton(Int16(tzj_info.dst_offset)))
        Base.write(io, hton(UInt8(tzj_info.designation_index - 1)))
    end

    for char in combined_designation
        Base.write(io, hton(UInt8(char)))
    end

    return nothing
end
