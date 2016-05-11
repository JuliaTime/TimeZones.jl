
# import Base.Dates: UTInstant, DateTime, TimeZone, Millisecond
using Base.Dates
import Base.Dates: value
import Base: ==, isequal, isless


abstract TimeError <: Exception

type AmbiguousTimeError <: TimeError
    dt::DateTime
    tz::TimeZone
end
Base.showerror(io::IO, e::AmbiguousTimeError) = print(io, "Local DateTime $(e.dt) is ambiguious");

type NonExistentTimeError <: TimeError
    dt::DateTime
    tz::TimeZone
end
Base.showerror(io::IO, e::NonExistentTimeError) = print(io, "DateTime $(e.dt) does not exist within $(string(e.tz))");

# Note: The Olson Database rounds offset precision to the nearest second
# See "America/New_York" notes in Olson file "northamerica" for an example.
immutable Offset
    utc::Second  # Standard offset from UTC
    dst::Second  # Addition daylight saving time offset applied to UTC offset

    function Offset(utc_offset::Second, dst_offset::Second=Second(0))
        new(utc_offset, dst_offset)
    end
end

function Offset(utc_offset::Integer, dst_offset::Integer=0)
    Offset(Second(utc_offset), Second(dst_offset))
end

# Using type Symbol instead of AbstractString for name since it
# gets us ==, and hash for free.

"""
    FixedTimeZone

A `TimeZone` with a constant offset for all of time.
"""
immutable FixedTimeZone <: TimeZone
    name::Symbol
    offset::Offset
end

"""
    FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0) -> FixedTimeZone

Constructs a `FixedTimeZone` with the given `name`, UTC offset (in seconds), and DST offset
(in seconds).
"""
function FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0)
    FixedTimeZone(Symbol(name), Offset(utc_offset, dst_offset))
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
    const regex = r"""
    ^(?|
        UTC([+-]\d{1,2})?
        |
        (?:UTC(?=[+-]))?
        ([+-]?\d{2})
        (?|
            (\d{2})
            |
            \:(\d{2})
            (?:\:(\d{2}))?
        )
    )$
    """x

    m = match(regex, s)
    m == nothing && throw(ArgumentError("Unrecognized time zone: $s"))

    values = map(n -> n == nothing ? 0 : Base.parse(Int, n), m.captures)

    if values == [0, 0, 0]
        name = "UTC"
    elseif values[3] == 0
        name = @sprintf("UTC%+03d:%02d", values[1:2]...)
    else
        name = @sprintf("UTC%+03d:%02d:%02d", values...)
    end

    if values[1] < 0
        for i in 2:length(values)
            values[i] = -values[i]
        end
    end

    offset = values[1] * 3600 + values[2] * 60 + values[3]
    return FixedTimeZone(name, offset)
end

immutable Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(x::Transition,y::Transition) = isless(x.utc_datetime,y.utc_datetime)

"""
    VariableTimeZone

A `TimeZone` with an offset that changes over time.
"""
immutable VariableTimeZone <: TimeZone
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

type UnhandledTimeError <: TimeError
    tz::VariableTimeZone
end
Base.showerror(io::IO, e::UnhandledTimeError) = print(io, "TimeZone $(string(e.tz)) does not handle dates on or after $(get(e.tz.cutoff)) UTC")

# """
#     ZonedDateTime

# A `DateTime` that includes `TimeZone` information.
# """

immutable ZonedDateTime <: TimeType
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
    possible_dates(dt, tz, from_utc=false) -> Array{Tuple{DateTime,FixedTimeZone}}

Produces a list of possible UTC `DateTime`s given a local `DateTime` and a
`VariableTimeZone`. Results are returned in ascending order.
"""
function possible_dates(dt::DateTime, tz::VariableTimeZone; from_utc::Bool=false)
    possible = Tuple{DateTime,FixedTimeZone}[]
    t = tz.transitions

    # Determine the earliest and latest possible UTC DateTime
    # that this local DateTime could be.
    if from_utc
        earliest = latest = dt
    else
        # TODO: Alternatively we should only look at the range of offsets available within
        # this TimeZone.
        earliest = dt + MIN_OFFSET
        latest = dt + MAX_OFFSET
    end

    # Determine the earliest transition the local DateTime could
    # occur within.
    i = searchsortedlast(
        t, earliest,
        by=v -> isa(v, Transition) ? v.utc_datetime : v,
    )
    i = max(i, 1)

    n = length(t)
    while i <= n && t[i].utc_datetime <= latest
        # Convert the given DateTime into UTC
        utc_dt = from_utc ? dt : dt - t[i].zone.offset

        if utc_dt >= t[i].utc_datetime && (i == n || utc_dt < t[i + 1].utc_datetime)
            push!(possible, (utc_dt, t[i].zone))
        end

        i += 1
    end

    return possible
end


"""
    ZonedDateTime(dt::DateTime, tz::TimeZone; from_utc=false) -> ZonedDateTime

Construct a `ZonedDateTime` by applying a `TimeZone` to a `DateTime`. When the `from_utc`
keyword is true the given `DateTime` is assumed to be in UTC instead of in local time and is
converted to the specified `TimeZone`.  Note that when `from_utc` is true the given
`DateTime` can never be ambiguious.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone; from_utc::Bool=false)
    possible = possible_dates(dt, tz; from_utc=from_utc)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
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
ambiguious within the given time zone you can set `occurrence` to a positive integer to
resolve the ambiguity.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone, occurrence::Integer)
    possible = possible_dates(dt, tz)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(dt, tz))
    elseif occurrence > 0
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(dt, tz))
    end
end

"""
    ZonedDateTime(dt::DateTime, tz::VariableTimeZone, is_dst::Bool) -> ZonedDateTime

Construct a `ZonedDateTime` by applying a `TimeZone` to a `DateTime`. If the `DateTime` is
ambiguious within the given time zone you can set `is_dst` to resolve the ambiguity.
"""
function ZonedDateTime(dt::DateTime, tz::VariableTimeZone, is_dst::Bool)
    possible = possible_dates(dt, tz)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(dt, tz))
    elseif num == 2
        mask = [zone.offset.dst > Second(0) for (utc_dt, zone) in possible]

        # Mask is expected to be unambiguous.
        !($)(mask...) && throw(AmbiguousTimeError(dt, tz))

        occurrence = is_dst ? findfirst(mask) : findfirst(!mask)
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(dt, tz))
    end
end


"""
    ZonedDateTime(zdt::ZonedDateTime, tz::TimeZone) -> ZonedDateTime

Converts a `ZonedDateTime` from its current `TimeZone` into the specified `TimeZone`.
"""
function ZonedDateTime(zdt::ZonedDateTime, tz::VariableTimeZone)
    i = searchsortedlast(
        tz.transitions, zdt.utc_datetime,
        by=v -> typeof(v) == Transition ? v.utc_datetime : v,
    )

    if i == 0
        throw(NonExistentTimeError(localtime(zdt), tz))
    end

    zone = tz.transitions[i].zone
    return ZonedDateTime(zdt.utc_datetime, tz, zone)
end

function ZonedDateTime(zdt::ZonedDateTime, tz::FixedTimeZone)
    return ZonedDateTime(zdt.utc_datetime, tz, tz)
end


# Convenience constructors
@doc """
    ZonedDateTime(y, [m, d, h, mi, s, ms], tz, [amb]) -> DateTime

Construct a `ZonedDateTime` type by parts. Arguments `y, m, ..., ms` must be convertible to
`Int64` and `tz` must be a `TimeZone`. If the given `DateTime` is ambiguious in the given
`TimeZone` then `amb` can be supplied to resolve ambiguity.
""" ZonedDateTime

@optional function ZonedDateTime(y::Integer, m::Integer=1, d::Integer=1, h::Integer=0, mi::Integer=0, s::Integer=0, ms::Integer=0, tz::VariableTimeZone, amb::Union{Integer,Bool})
    ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz, amb)
end

@optional function ZonedDateTime(y::Integer, m::Integer=1, d::Integer=1, h::Integer=0, mi::Integer=0, s::Integer=0, ms::Integer=0, tz::TimeZone)
    ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz)
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

# Equality
==(a::ZonedDateTime, b::ZonedDateTime) = a.utc_datetime == b.utc_datetime
isless(a::ZonedDateTime, b::ZonedDateTime) = isless(a.utc_datetime, b.utc_datetime)

function isequal(a::ZonedDateTime, b::ZonedDateTime)
    isequal(a.utc_datetime, b.utc_datetime) && isequal(a.timezone, b.timezone)
end

function ==(a::VariableTimeZone, b::VariableTimeZone)
    a.name == b.name && a.transitions == b.transitions
end
