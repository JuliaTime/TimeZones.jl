
# import Base.Dates: UTInstant, DateTime, TimeZone, Millisecond
using Base.Dates
import Base.Dates: value
import Base: ==


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

doc"""A `TimeZone` with a constant offset for all of time."""
immutable FixedTimeZone <: TimeZone
    name::Symbol
    offset::Offset
end

doc"""
`FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0) -> FixedTimeZone`

Constructs a `FixedTimeZone` with the given `name`, UTC offset (in seconds), and DST offset
(in seconds).
"""
function FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0)
    FixedTimeZone(symbol(name), Offset(utc_offset, dst_offset))
end

doc"""
`FixedTimeZone(::AbstractString) -> FixedTimeZone`

Constructs a `FixedTimeZone` with a UTC offset from a string. Resulting `FixedTimeZone` will
be named like \"UTC±HH:MM\".

Examples: \"UTC+6\", \"-1330\", \"15:45:21\"
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
    m == nothing && error("Unrecognized timezone: $s")

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

doc"""A `TimeZone` with an offset that changes over time."""
immutable VariableTimeZone <: TimeZone
    name::Symbol
    transitions::Vector{Transition}
end

function VariableTimeZone(name::AbstractString, transitions::Vector{Transition})
    return VariableTimeZone(symbol(name), transitions)
end

doc"""A `DateTime` that includes `TimeZone` information."""
immutable ZonedDateTime <: TimeType
    utc_datetime::DateTime
    timezone::TimeZone
    zone::FixedTimeZone  # The current zone for the utc_datetime.
end

doc"""
Produces a list of possible UTC DateTimes given a local DateTime
and a `VariableTimeZone`. Results are returned in ascending order.
"""
function possible_dates(local_dt::DateTime, tz::VariableTimeZone; from_utc::Bool=false)
    possible = Tuple{DateTime,FixedTimeZone}[]
    t = tz.transitions

    # Determine the earliest and latest possible UTC DateTime
    # that this local DateTime could be.
    if from_utc
        earliest = latest = local_dt
    else
        # TODO: Alternatively we should only look at the range of offsets available within
        # this TimeZone.
        earliest = local_dt + MIN_OFFSET
        latest = local_dt + MAX_OFFSET
    end

    # Determine the earliest transition the local DateTime could
    # occur within.
    i = searchsortedlast(
        t, earliest,
        by=v -> typeof(v) == Transition ? v.utc_datetime : v,
    )
    i = max(i, 1)

    n = length(t)
    while i <= n && t[i].utc_datetime <= latest
        utc_dt = from_utc ? local_dt : local_dt - t[i].zone.offset

        if utc_dt >= t[i].utc_datetime && (i == n || utc_dt < t[i + 1].utc_datetime)
            push!(possible, (utc_dt, t[i].zone))
        end

        i += 1
    end

    return possible
end

doc"""
`ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, occurrence::Integer=0; from_utc::Bool=false) -> ZonedDateTime`

Constructs a `ZonedDateTime` given a local `DateTime` and a `TimeZone`. If the local
`DateTime` is ambiguious in the given time zone you can set `occurrence` to a positive
integer to resolve the ambiuity. When the `from_utc` keyword is true the given `DateTime` is
processed as if it is in UTC.
"""
function ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, occurrence::Integer=0; from_utc::Bool=false)
    possible = possible_dates(local_dt, tz; from_utc=from_utc)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
    elseif occurrence > 0
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(local_dt, tz))
    end
end

doc"""
`ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, is_dst::Bool; from_utc::Bool=false) -> ZonedDateTime`

Constructs a `ZonedDateTime` given a local `DateTime` and a `TimeZone`. If the local
`DateTime` is ambiguious in the given time zone you can set `is_dst` to resolve the
ambiuity. When the `from_utc` keyword is true the given `DateTime` is processed as if it is
in UTC.
"""
function ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, is_dst::Bool; from_utc::Bool=false)
    possible = possible_dates(local_dt, tz; from_utc=from_utc)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
    elseif num == 2
        mask = [zone.offset.dst > Second(0) for (utc_dt, zone) in possible]

        # Mask is expected to be unambiguous.
        !($)(mask...) && throw(AmbiguousTimeError(local_dt, tz))

        occurrence = is_dst ? findfirst(mask) : findfirst(!mask)
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(local_dt, tz))
    end
end

doc"""
`ZonedDateTime(local_dt::DateTime, tz::FixedTimeZone; from_utc::Bool=false) -> ZonedDateTime`

Constructs a `ZonedDateTime` given a local `DateTime` and a `FixedTimeZone`. When the
`from_utc` keyword is true the given `DateTime` is processed as if it is in UTC.
"""
function ZonedDateTime(local_dt::DateTime, tz::FixedTimeZone; from_utc::Bool=false)
    utc_dt = from_utc ? local_dt : local_dt - tz.offset
    return ZonedDateTime(utc_dt, tz, tz)
end

doc"""
`ZonedDateTime(zdt::DateTime, tz::TimeZone) -> ZonedDateTime`

Converts a `ZonedDateTime` from the current `TimeZone` into the specified `tz`.
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

function ZonedDateTime(parts::Union{Period,TimeZone}...)
    periods = Period[]
    timezone = Nullable{TimeZone}()
    for part in parts
        if isa(part, Period)
            push!(periods, part)
        elseif isnull(timezone)
            timezone = Nullable{TimeZone}(part)
        else
            throw(ArgumentError("Multiple timezones found"))
        end
    end

    isnull(timezone) && throw(ArgumentError("Missing timezone"))
    return ZonedDateTime(DateTime(periods...), get(timezone))
end

# Equality
==(a::ZonedDateTime, b::ZonedDateTime) = a.utc_datetime == b.utc_datetime
Base.isless(a::ZonedDateTime, b::ZonedDateTime) = isless(a.utc_datetime, b.utc_datetime)

function ==(a::VariableTimeZone, b::VariableTimeZone)
    a.name == b.name && a.transitions == b.transitions
end
