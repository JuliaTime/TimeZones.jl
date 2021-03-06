struct Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(a::Transition, b::Transition) = isless(a.utc_datetime, b.utc_datetime)

"""
    VariableTimeZone

A `TimeZone` with an offset that changes over time.
"""
struct VariableTimeZone <: TimeZone
    name::String
    transitions::Vector{Transition}
    cutoff::Union{DateTime,Nothing}

    function VariableTimeZone(name::AbstractString, transitions::Vector{Transition}, cutoff::Union{DateTime,Nothing}=nothing)
        new(name, transitions, cutoff)
    end
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
