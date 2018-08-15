
# import Compat.Dates: UTInstant, DateTime, TimeZone, Millisecond
using Compat
using Compat.Dates
using Compat: AbstractDateTime
import Compat.Dates: value, argerror, validargs
import Base: promote_rule, ==, hash, isequal, isless, typemin, typemax
import Compat: xor

const FIXED_TIME_ZONE_REGEX = r"""
    ^(?|
        UTC
        (?:
            (?<sign>[+-])
            (?<hour>\d{1,2})
        )?
    |
        (?<sign>[+-])
        (?<hour>\d{2})
    |
        (?:UTC(?=[+-]))?
        (?<sign>[+-])?
        (?<hour>\d{2})
        (?|
            (?(hour)\:(?<minute>\d{2}))
            (?(minute)\:(?<second>\d{2}))?
        |
            (?(hour)(?<minute>\d{2}))
        )
    )$
    """x

# Using type Symbol instead of AbstractString for name since it
# gets us ==, and hash for free.

"""
    FixedTimeZone

A `TimeZone` with a constant offset for all of time.
"""
struct FixedTimeZone <: TimeZone
    name::Symbol
    offset::UTCOffset
end

FixedTimeZone(name::AbstractString, offset::UTCOffset) = FixedTimeZone(Symbol(name), offset)

"""
    FixedTimeZone(name, utc_offset, dst_offset=0) -> FixedTimeZone

Constructs a `FixedTimeZone` with the given `name`, UTC offset (in seconds), and DST offset
(in seconds).
"""
function FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0)
    FixedTimeZone(Symbol(name), UTCOffset(utc_offset, dst_offset))
end

function FixedTimeZone(name::AbstractString, utc_offset::Second, dst_offset::Second=Second(0))
    FixedTimeZone(Symbol(name), UTCOffset(utc_offset, dst_offset))
end

"""
    FixedTimeZone(::AbstractString) -> FixedTimeZone

Constructs a `FixedTimeZone` with a UTC offset from a string. Resulting `FixedTimeZone` will
be named like \"UTC±HH:MM[:SS]\".

# Examples
```julia
julia> FixedTimeZone(\"UTC+6\")
UTC+06:00

julia> FixedTimeZone(\"-1330\")
UTC-13:30

julia> FixedTimeZone(\"15:45:21\")
UTC+15:45:21
```
"""
function FixedTimeZone(s::AbstractString)
    m = match(FIXED_TIME_ZONE_REGEX, s)
    m === nothing && throw(ArgumentError("Unrecognized time zone: $s"))

    coefficient = m[:sign] == "-" ? -1 : 1
    sig = coefficient < 0 ? '-' : '+'
    hour = m[:hour] === nothing ? 0 : parse(Int, m[:hour])
    minute = m[:minute] === nothing ? 0 : parse(Int, m[:minute])
    second = m[:second] === nothing ? 0 : parse(Int, m[:second])

    if hour == 0 && minute == 0 && second == 0
        name = "UTC"
    elseif second == 0
        name = @sprintf("UTC%c%02d:%02d", sig, hour, minute)
    else
        name = @sprintf("UTC%c%02d:%02d:%02d", sig, hour, minute, second)
    end

    offset = coefficient * (hour * 3600 + minute * 60 + second)
    return FixedTimeZone(name, offset)
end

struct Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(x::Transition,y::Transition) = isless(x.utc_datetime,y.utc_datetime)

"""
    VariableTimeZone

A `TimeZone` with an offset that changes over time.
"""
struct VariableTimeZone <: TimeZone
    name::Symbol
    transitions::Vector{Transition}
    cutoff::Nullable{DateTime}
end

function VariableTimeZone(name::AbstractString, transitions::Vector{Transition}, cutoff::Nullable{DateTime})
    return VariableTimeZone(Symbol(name), transitions, cutoff)
end

function VariableTimeZone(name::AbstractString, transitions::Vector{Transition}, cutoff::DateTime)
    return VariableTimeZone(Symbol(name), transitions, Nullable(cutoff))
end

function VariableTimeZone(name::AbstractString, transitions::Vector{Transition})
    return VariableTimeZone(Symbol(name), transitions, Nullable{DateTime}())
end


# """
#     ZonedDateTime

# A `DateTime` that includes `TimeZone` information.
# """

struct ZonedDateTime <: AbstractDateTime
    utc_datetime::DateTime
    timezone::TimeZone
    zone::FixedTimeZone  # The current zone for the utc_datetime.

    function ZonedDateTime(utc_datetime::DateTime, timezone::TimeZone, zone::FixedTimeZone)
        return new(utc_datetime, timezone, zone)
    end

    function ZonedDateTime(utc_datetime::DateTime, timezone::VariableTimeZone, zone::FixedTimeZone)
        if utc_datetime >= get(timezone.cutoff, typemax(DateTime))
            throw(UnhandledTimeError(timezone))
        end

        return new(utc_datetime, timezone, zone)
    end
end

"""
    ZonedDateTime(dt::DateTime, tz::TimeZone; from_utc=false) -> ZonedDateTime

Construct a `ZonedDateTime` by applying a `TimeZone` to a `DateTime`. When the `from_utc`
keyword is true the given `DateTime` is assumed to be in UTC instead of in local time and is
converted to the specified `TimeZone`.  Note that when `from_utc` is true the given
`DateTime` will always exists and is never ambiguous.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone; from_utc::Bool=false)
    possible = interpret(dt, tz, from_utc ? UTC : Local)

    num = length(possible)
    if num == 1
        return first(possible)
    elseif num == 0
        throw(NonExistentTimeError(dt, tz))
    else
        throw(AmbiguousTimeError(dt, tz))
    end
end

function ZonedDateTime(dt::DateTime, tz::FixedTimeZone; from_utc::Bool=false)
    utc_dt = from_utc ? dt : dt - tz.offset
    return ZonedDateTime(utc_dt, tz, tz)
end

"""
    ZonedDateTime(dt::DateTime, tz::VariableTimeZone, occurrence::Integer) -> ZonedDateTime

Construct a `ZonedDateTime` by applying a `TimeZone` to a `DateTime`. If the `DateTime` is
ambiguous within the given time zone you can set `occurrence` to a positive integer to
resolve the ambiguity.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone, occurrence::Integer)
    possible = interpret(dt, tz, Local)

    num = length(possible)
    if num == 1
        return first(possible)
    elseif num == 0
        throw(NonExistentTimeError(dt, tz))
    elseif occurrence > 0
        return possible[occurrence]
    else
        throw(AmbiguousTimeError(dt, tz))
    end
end

"""
    ZonedDateTime(dt::DateTime, tz::VariableTimeZone, is_dst::Bool) -> ZonedDateTime

Construct a `ZonedDateTime` by applying a `TimeZone` to a `DateTime`. If the `DateTime` is
ambiguous within the given time zone you can set `is_dst` to resolve the ambiguity.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone, is_dst::Bool)
    possible = interpret(dt, tz, Local)

    num = length(possible)
    if num == 1
        return first(possible)
    elseif num == 0
        throw(NonExistentTimeError(dt, tz))
    elseif num == 2
        mask = [isdst(zdt.zone.offset) for zdt in possible]

        # Mask is expected to be unambiguous.
        !xor(mask...) && throw(AmbiguousTimeError(dt, tz))

        occurrence = findfirst(d -> d == is_dst, mask)
        return possible[occurrence]
    else
        throw(AmbiguousTimeError(dt, tz))
    end
end

# Convenience constructors
@doc """
    ZonedDateTime(y, [m, d, h, mi, s, ms], tz, [amb]) -> DateTime

Construct a `ZonedDateTime` type by parts. Arguments `y, m, ..., ms` must be convertible to
`Int64` and `tz` must be a `TimeZone`. If the given `DateTime` is ambiguous in the given
`TimeZone` then `amb` can be supplied to resolve ambiguity.
""" ZonedDateTime

@optional function ZonedDateTime(y::Integer, m::Integer=1, d::Integer=1, h::Integer=0, mi::Integer=0, s::Integer=0, ms::Integer=0, tz::VariableTimeZone, amb::Union{Integer,Bool})
    ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz, amb)
end

@optional function ZonedDateTime(y::Integer, m::Integer=1, d::Integer=1, h::Integer=0, mi::Integer=0, s::Integer=0, ms::Integer=0, tz::TimeZone)
    ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz)
end

# Parsing constructor. Note we typically don't support passing in time zone information as a
# string since we cannot do not know if we need to support resolving ambiguity.
function ZonedDateTime(y::Int64, m::Int64, d::Int64, h::Int64, mi::Int64, s::Int64, ms::Int64, tz::AbstractString)
    ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), TimeZone(tz))
end


function ZonedDateTime(parts::Union{Period,TimeZone}...)
    periods = Period[]
    timezone = Nullable{TimeZone}()
    for part in parts
        if isa(part, Period)
            push!(periods, part)
        elseif isnull(timezone)
            timezone = Nullable{TimeZone}(part)
        else
            throw(ArgumentError("Multiple time zones found"))
        end
    end

    isnull(timezone) && throw(ArgumentError("Missing time zone"))
    return ZonedDateTime(DateTime(periods...), get(timezone))
end

# Promotion

# Because of the promoting fallback definitions for TimeType, we need a special case for
# undefined promote_rule on TimeType types.
# Otherwise, typejoin(T,S) is called (returning TimeType) so no conversion happens, and
# isless(promote(x,y)...) is called again, causing a stack overflow.
function promote_rule(::Type{T}, ::Type{S}) where {T<:TimeType, S<:ZonedDateTime}
    error("no promotion exists for ", T, " and ", S)
end

# Equality
==(a::ZonedDateTime, b::ZonedDateTime) = a.utc_datetime == b.utc_datetime
isless(a::ZonedDateTime, b::ZonedDateTime) = isless(a.utc_datetime, b.utc_datetime)
isequal(a::ZonedDateTime, b::ZonedDateTime) = isequal(a.utc_datetime, b.utc_datetime)

"""
    hash(::ZonedDateTime, h)

Compute an integer hash code for a ZonedDateTime by hashing the `utc_datetime` field.
`hash(:utc_instant, h)` is used to avoid collisions with `DateTime` hashes.
"""
function hash(zdt::ZonedDateTime, h::UInt)
    h = hash(:utc_instant, h)
    h = hash(zdt.utc_datetime, h)
    return h
end

function ==(a::VariableTimeZone, b::VariableTimeZone)
    a.name == b.name && a.transitions == b.transitions
end

function hash(tz::VariableTimeZone, h::UInt)
    h = hash(tz.name, h)
    h = hash(tz.transitions, h)
    h = hash(tz.cutoff, h)
    return h
end

typemin(::Type{ZonedDateTime}) = ZonedDateTime(typemin(DateTime), utc_tz; from_utc=true)
typemax(::Type{ZonedDateTime}) = ZonedDateTime(typemax(DateTime), utc_tz; from_utc=true)

function validargs(::Type{ZonedDateTime}, y::Int64, m::Int64, d::Int64, h::Int64, mi::Int64, s::Int64, ms::Int64, tz::AbstractString)
    err = validargs(DateTime, y, m, d, h, mi, s, ms)
    isnull(err) || return err
    istimezone(tz) || return argerror("TimeZone: \"$str\" is not a recognized time zone")
    return argerror()
end
