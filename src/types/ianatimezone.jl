
# This is extremely redundant but still only about 8MB for each of our 2 tables
# and it avoids any need to write a smarter but more CPU time expensive perfect hash
# This needs to be big enough to avoid any collisions
# also extra size is useful because it means we are probably safe if new timezones are added
const IANA_TABLE_SIZE = 2^20

const IANA_TIMEZONES = Vector{VariableTimeZone}(undef, IANA_TABLE_SIZE)

# TODO: maybe fill this during build(), probably by generating a julia file.
# That way we can avoid actually instantitating every timezone til it is needed.
const IANA_NAMES = Vector{String}(undef, IANA_TABLE_SIZE)
function init_IANA_NAMES!()  # this is run by __init__ (at least for now)
    for name in timezone_names()
        # TODO: we should workout how to filter out FixedTimeZones here
        mod_id = iana_mod_id(name)
        # Important: Make sure our hash is perfect (even module the table size)
        isassigned(IANA_NAMES, mod_id) && error("hash collision for $tz, at $mod_id")
        IANA_NAMES[mod_id] = name
    end
    return IANA_NAMES
end

# have checked that this is perfect
perfect_hash(tz::VariableTimeZone, h=zero(UInt)) = perfect_hash(tz.name, h)
function perfect_hash(name::AbstractString, h=zero(UInt))
    h = hash(:timezone, h)
    h = hash(name, h)
    return h
end

iana_mod_id(str_or_var_tz) = iana_mod_id(perfect_hash(str_or_var_tz))
iana_mod_id(id::UInt) = mod1(id, IANA_TABLE_SIZE)

function is_standard_iana(str::AbstractString)
    mod_id = iana_mod_id(str)
    return isassigned(IANA_NAMES, mod_id) && IANA_NAMES[mod_id] == str
end

function get_iana_timezone!(str::AbstractString)
    mod_id = iana_mod_id(str)
    if isassigned(IANA_TIMEZONES, mod_id)
        IANA_TIMEZONES[mod_id]
    else
        tz_path = joinpath(TZData.COMPILED_DIR, split(str, "/")...)
        tz, class = deserialize(tz_path)
        # TODO: maybe here is where we check if it is a FixedTimeZone, and if so don't remember it?
        if tz isa VariableTimeZone
            IANA_TIMEZONES[mod_id] = tz
            return IANATimeZone(perfect_hash(str))
        else
            # it is a FixedTimeZone, we are not going to use a IANATimeZone
            return tz
        end
    end
end

function get_iana_timezone!(id::UInt)
    mod_id = iana_mod_id(id)
    if isassigned(IANA_NAMES, mod_id)
        name = IANA_NAMES[mod_id]
        return get_iana_timezone!(name)
    else
        error(
            "$id does not correspond to any known IANA timezone. " *
            "Check you are using the right version of the IANA database.",
        )
    end
end


"""
    IANATimeZone(::AbstractString) <: AbstractVariableTimeZone

A type for representing a standard variable IANA TimeZome from the tzdata.
Under-the-hood it stores only a unique integer identifier.
"""
struct IANATimeZone <: TimeZone
    # id must be a hash of the corresponding Variable/FixedTimeZone
    # and it is only possible if `hash` on all timezones in tzdata happens to be perfect
    # This is the real hash, not the hash modulo IANA_TABLE_SIZE
    # because that way we can in the future change IANA_TABLE_SIZE and not invalidate old
    # serialized data.
    id::UInt
end

function IANATimeZone(name::AbstractString)
    return IANATimeZone(perfect_hash(name))
end

backing_timezone(itz::IANATimeZone) = get_iana_timezone!(itz.id)

Base.:(==)(a::IANATimeZone, b::IANATimeZone) = a.id == b.id
Base.:(==)(a::IANATimeZone, b::TimeZone) = backing_timezone(a) == b
Base.:(==)(b::TimeZone, a::IANATimeZone) = backing_timezone(a) == b

# TODO: we have the hash, it seems like we should be able to use that to get seeded hash
Base.hash(a::IANATimeZone, seed::UInt) = hash(backing_timezone(a), seed)

name(a::IANATimeZone) = name(backing_timezone(a))
transitions(tz::IANATimeZone) = transitions(backing_timezone(tz))

# TODO: should i just make this check the fields of VariableTimeZone and just delegate all?
function Base.getproperty(tz::IANATimeZone, s::Symbol)
    if s === :name
        return name(tz)
    elseif s == :transitions
        return transitions(tz)
    else
        return getfield(tz, s)
    end
end
function Base.hasproperty(tz::IANATimeZone, s::Symbol)
    return s === :name || s === :transitions || hasfield(IANATimeZone, s)
end




""""
    _do_and_rewrap(f, arg1, tz::IANATimeZone, args...; kwargs...)

Run the function `f(arg1, backing_timezone(tz), args...; kwargs...)`
which must return a `ZonedDateTime`, with the backing timezone.
Replace the timezone field with `tz` (which should be equivalent).
"""
function _do_and_rewrap(f, arg1, tz::IANATimeZone, args...; kwargs...)
    backed_tz = backing_timezone(tz)
    backed_zdt::ZonedDateTime = f(arg1, backing_timezone(tz), args...; kwargs...)
        # make it store tz rather than the equiv backing timezone, other fields the same
    return ZonedDateTime(backed_zdt.utc_datetime, tz, backed_zdt.zone)
end


Base.show(io::IO, tz::IANATimeZone) = show(io, backing_timezone(tz))
Base.print(io::IO, tz::IANATimeZone) = print(io, backing_timezone(tz))
