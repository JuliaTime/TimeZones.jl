function combine_designations(abbrs)
    # Comparing by reverse string length results maximal re-use of null-terminated strings
    unique_abbrs = sort!(unique(abbrs), by=length, rev=true)
    str, unique_indices = _combine_designations(unique_abbrs)
    mapping = Dict(unique_abbrs .=> unique_indices)

    indices = [mapping[abbr] for abbr in abbrs]
    return str, indices
end

function _combine_designations(abbrs::AbstractVector{<:AbstractString})
    # Note: Could make use of an `OrderedDict` to combine these
    abbr_position = Dict{String,Int}()
    abbr_order = Vector{String}()

    result = ""
    indices = Vector{Int}(undef, length(abbrs))
    for (i, abbr) in enumerate(abbrs)
        indices[i] = get!(abbr_position, abbr) do
            # Determine if the new abbreviation is already present as a trailing substring
            # in a previously added abbreviation. Making use of the properties of
            # null-terminated strings to reduce the output.
            for stored in abbr_order
                if endswith(stored, abbr)
                    pos = abbr_position[stored] + ncodeunits(stored) - ncodeunits(abbr)
                    return pos
                end
            end

            # Add full abbreviation
            pos = ncodeunits(result) + 1
            result *= "$abbr\0"
            push!(abbr_order, abbr)

            return pos
        end
    end

    return result, indices
end

"""
    TZFile.write(io::IO, tz::TimeZone; version::Char=TZFile.WRITE_VERSION)

Writes the time zone to the I/O stream in the
[POSIX tzfile](https://data.iana.org/time-zones/data/tzfile.5.txt) format.
"""
function write end

function write(io::IO, tz::FixedTimeZone; version::Char=WRITE_VERSION)
    combined_designation, designation_indices = combine_designations([tz.name])

    transition_times = Vector{Int32}()
    ttinfo = TransitionTimeInfo(
        Dates.value(Second(tz.offset.std) + Second(tz.offset.dst)),
        false,
        only(designation_indices),
    )
    transition_types = [ttinfo]

    write_signature(io)
    write_version(io; version)
    write_content(io; transition_times, transition_types, combined_designation)

    if version != '\0'
        transition_times = Vector{Int64}()

        write_signature(io)
        write_version(io; version)
        write_content(io; transition_times, transition_types, combined_designation)
    end
end

function write(io::IO, tz::VariableTimeZone; version::Char=WRITE_VERSION)
    combined_designation, designation_indices = combine_designations(t.zone.name for t in tz.transitions)

    function compatible_transition(t::Transition)
        return typemin(Int32) <= datetime2unix(t.utc_datetime) <= typemax(Int32)
    end

    transition_times = sizehint!(Vector{Int32}(), length(tz.transitions))
    transition_types = sizehint!(Vector{TransitionTimeInfo}(), length(tz.transitions))
    for (i, t) in enumerate(filter(compatible_transition, tz.transitions))
        # TODO: Sorting provides us a way to avoid checking for the sentinel on each loop
        timestamp = datetime2timestamp(t.utc_datetime, Int32)

        ttinfo = TransitionTimeInfo(
            Dates.value(Second(t.zone.offset.std) + Second(t.zone.offset.dst)),
            isdst(t.zone.offset),
            designation_indices[i]
        )

        push!(transition_times, timestamp)
        push!(transition_types, ttinfo)
    end

    write_signature(io)
    write_version(io; version)
    write_content(io; transition_times, transition_types, combined_designation)

    if version != '\0'
        transition_times = sizehint!(Vector{Int64}(), length(tz.transitions))
        transition_types = empty!(transition_types)
        for (i, t) in enumerate(tz.transitions)
            # TODO: Sorting provides us a way to avoid checking for the sentinel on each loop
            timestamp = datetime2timestamp(t.utc_datetime, Int64)

            ttinfo = TransitionTimeInfo(
                Dates.value(Second(t.zone.offset.std) + Second(t.zone.offset.dst)),
                isdst(t.zone.offset),
                designation_indices[i]
            )

            push!(transition_times, timestamp)
            push!(transition_types, ttinfo)
        end

        write_signature(io)
        write_version(io; version)
        write_content(io; transition_times, transition_types, combined_designation)
    end
end

write_signature(io::IO) = Base.write(io, b"TZif")  # Magic four-byte ASCII sequence
write_version(io::IO; version::Char) = Base.write(io, UInt8(version))  # Single-byte identifying the tzfile version

function write_content(
    io::IO;
    transition_times::Vector{T},
    transition_types::Vector{TransitionTimeInfo},
    combined_designation::AbstractString,
) where T <: Union{Int32, Int64}
    if length(transition_times) > 0
        unique_transition_types = unique(transition_types)
        transition_indices = indexin(transition_types, unique_transition_types)
        transition_types = unique_transition_types

        @assert length(transition_times) == length(transition_indices)
    else
        transition_indices = Vector{Int}()
        transition_types = unique(transition_types)
    end

    Base.write(io, fill(hton(0x00), 15))  # Fifteen bytes reserved for future use

    # Six four-byte integer values
    Base.write(io, hton(Int32(0)))                            # tzh_ttisutcnt (currently ignored)
    Base.write(io, hton(Int32(0)))                            # tzh_ttisstdcnt (currently ignored)
    Base.write(io, hton(Int32(0)))                            # tzh_leapcnt (currently ignored)
    Base.write(io, hton(Int32(length(transition_times))))     # tzh_timecnt
    Base.write(io, hton(Int32(length(transition_types))))     # tzh_typecnt
    Base.write(io, hton(Int32(length(combined_designation)))) # tzh_charcnt

    for timestamp in transition_times
        Base.write(io, hton(timestamp))
    end

    for index in transition_indices
        Base.write(io, hton(UInt8(index - 1)))  # Convert 1-indexing to 0-indexing
    end

    for ttinfo in transition_types
        Base.write(io, hton(Int32(ttinfo.ut_offset)))
        Base.write(io, hton(UInt8(ttinfo.is_dst)))
        Base.write(io, hton(UInt8(ttinfo.designation_index - 1)))
    end

    for char in combined_designation
        Base.write(io, hton(UInt8(char)))
    end

    return nothing
end
