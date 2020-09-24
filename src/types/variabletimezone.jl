struct Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(a::Transition, b::Transition) = isless(a.utc_datetime, b.utc_datetime)

function Base.:(==)(a::Transition, b::Transition)
    return a.utc_datetime == b.utc_datetime && a.zone == b.zone
end

function Base.isequal(a::Transition, b::Transition)
    return isequal(a.utc_datetime, b.utc_datetime) && isequal(a.zone, b.zone)
end

"""
    VariableTimeZone

A `TimeZone` with an offset that changes over time.
"""
mutable struct VariableTimeZone <: TimeZone
    name::String
    transitions::Vector{Transition}
    cutoff::Union{DateTime,Nothing}
    index::Int

    function VariableTimeZone(name::AbstractString, transitions::Vector{Transition}, cutoff::Union{DateTime,Nothing}=nothing)
        tz = new(name, transitions, cutoff)
        tz.index = add!(_TIME_ZONES, tz)
        return tz
    end
end

# Overload serialization to ensure that `VariableTimeZone` serialization doesn't transfer
# state information which is specific to the current Julia process.
function Serialization.serialize(s::AbstractSerializer, tz::VariableTimeZone)
    Serialization.serialize_type(s, typeof(tz))
    serialize(s, tz.name)
    serialize(s, tz.transitions)
    serialize(s, tz.cutoff)
end

function Serialization.deserialize(s::AbstractSerializer, ::Type{VariableTimeZone})
    name = deserialize(s)
    transitions = deserialize(s)
    cutoff = deserialize(s)

    return VariableTimeZone(name, transitions, cutoff)
end

name(tz::VariableTimeZone) = tz.name

function rename(tz::VariableTimeZone, name::AbstractString)
    VariableTimeZone(name, tz.transitions, tz.cutoff)
end

function Base.:(==)(a::VariableTimeZone, b::VariableTimeZone)
    a.name == b.name && a.transitions == b.transitions
end

function Base.isequal(a::VariableTimeZone, b::VariableTimeZone)
    return (
        isequal(a.name, b.name) &&
        isequal(a.transitions, b.transitions) &&
        isequal(a.cutoff, b.cutoff)
    )
end

function Base.hash(tz::VariableTimeZone, h::UInt)
    h = hash(:timezone, h)
    h = hash(tz.name, h)
    return h
end
