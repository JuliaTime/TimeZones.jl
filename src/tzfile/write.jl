# Number of seconds between the `typemin(DateTime)` and the UNIX epoch
const DATETIME_EPOCH = convert(Int64, datetime2unix(typemin(DateTime)))

struct TransitionTime
    ut_instant::Int64  # Seconds since UNIX epoch
    ut_offset::Int32   # Number of seconds to be added to Universal Time
    is_dst::Bool
    designation::String
end

function assemble_designations(abbrs)
    # Comparing by `endswith` results in maximal re-use of null-terminated strings
    unique_abbrs = sort!(unique(abbrs), lt=endswith)
    str, unique_indices = _assemble_designations(unique_abbrs)
    mapping = Dict(unique_abbrs .=> unique_indices)

    indices = [mapping[abbr] for abbr in abbrs]
    return str, indices
end

function _assemble_designations(abbrs::AbstractVector{<:AbstractString})
    # Note: Could make use of an `OrderedDict` to combine these
    abbr_position = Dict{String,Int}()
    abbr_order = Vector{String}()

    result = ""
    indices = Vector{Int}(undef, length(abbrs))
    for (i, abbr) in enumerate(abbrs)
        indices[i] = get!(abbr_position, abbr) do
            # Determine if the new abbreviation is already present as a trailing substring
            # in a previously added abbreviation. Making use of the properties of
            # null-terminated strings.
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

function write(io::IO, transitions::Vector{TransitionTime}; version::Char)
    designation_agg_str, designation_indices = assemble_designations(t.designation for t in transitions)

    transition_time_infos = map(enumerate(transitions)) do (i, t)
        (;
            ut_offset=t.ut_offset,
            is_dst=t.is_dst,
            designation_index=designation_indices[i],
        )
    end

    # TODO: Interface needs more thought. Definitely do need a index which maps the unique
    # `transition_time_infos` to each transition_time
    unique_transition_time_infos = unique(transition_time_infos)
    transition_time_indices = indexin(transition_time_infos, unique_transition_time_infos)
    transition_time_infos = unique_transition_time_infos

    @assert length(transitions) == length(transition_time_indices)

    Base.write(io, b"TZif")  # Magic four-byte ASCII sequence
    Base.write(io, UInt8(version))  # Single-byte identifying the tzfile version

    Base.write(io, fill(hton(0x00), 15))  # Fifteen bytes reserved for future use

    # Six four-byte integer values
    Base.write(io, hton(Int32(0)))                             # tzh_ttisutcnt (currently ignored)
    Base.write(io, hton(Int32(0)))                             # tzh_ttisstdcnt (currently ignored)
    Base.write(io, hton(Int32(0)))                             # tzh_leapcnt (currently ignored)
    Base.write(io, hton(Int32(length(transitions))))           # tzh_timecnt
    Base.write(io, hton(Int32(length(transition_time_infos)))) # tzh_typecnt
    Base.write(io, hton(Int32(length(designation_agg_str))))   # tzh_charcnt

    # Transition time and leap second time byte size
    T = version == '\0' ? Int32 : Int64

    # TODO: Sorting provides us a way to avoid checking on each loop
    for t in transitions
        timestamp = t.ut_instant

        # Convert timestamps of `typemin(DateTime)` to the `timestamp_min`
        if timestamp == DATETIME_EPOCH
            timestamp = transition_min(T)
        end

        Base.write(io, hton(T(timestamp)))
    end

    for index in transition_time_indices
        Base.write(io, hton(UInt8(index - 1)))  # Convert 1-indexing to 0-indexing
    end

    # tzh_typecnt ttinfo entries
    for tt in transition_time_infos
        Base.write(io, hton(Int32(tt.ut_offset)))
        Base.write(io, hton(UInt8(tt.is_dst)))
        Base.write(io, hton(UInt8(tt.designation_index - 1)))
    end

    for char in designation_agg_str
        Base.write(io, hton(UInt8(char)))
    end
end

function write(io::IO, tz::VariableTimeZone; version::Char)
    transitions = map(tz.transitions) do t
        TransitionTime(
            convert(Int64, datetime2unix(t.utc_datetime)),
            Dates.value(Second(t.zone.offset.std + t.zone.offset.dst)),
            isdst(t.zone.offset),
            t.zone.name,
        )
    end

    write(io, transitions; version)
end



