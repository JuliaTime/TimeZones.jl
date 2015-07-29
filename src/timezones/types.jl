
# import Base.Dates: UTInstant, DateTime, TimeZone, Millisecond
using Base.Dates
import Base.Dates: value

# Note: The Olsen Database rounds offset precision to the nearest second
# See "America/New_York" notes for an example.

abstract FixedTimeZone <: TimeZone

# Using type Symbol instead of AbstractString for name since it
# gets us ==, and hash for free.
immutable OffsetTimeZone <: FixedTimeZone
    name::Symbol
    offset::Second
end

immutable DaylightSavingTimeZone <: FixedTimeZone
    name::Symbol
    utc_offset::Second  # Standard offset from UTC
    dst_offset::Second  # Addition offset applied to UTC offset
end

function FixedTimeZone(name::Symbol, utc_offset::Second, dst_offset::Second)
    if value(dst_offset) == 0
        OffsetTimeZone(name, utc_offset)
    else
        DaylightSavingTimeZone(name, utc_offset, dst_offset)
    end
end

function FixedTimeZone(name::String, utc_offset::Int, dst_offset::Int=0)
    FixedTimeZone(symbol(name), Second(utc_offset), Second(dst_offset))
end

immutable Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(x::Transition,y::Transition) = isless(x.utc_datetime,y.utc_datetime)

# function Base.string(t::Transition)
#     return "$(t.utc_datetime), $(t.zone.name), $(t.zone.offset)"
# end

"""
A TimeZone that has a variable offset from UTC.
"""
immutable VariableTimeZone <: TimeZone
    name::Symbol
    transitions::Vector{Transition}
end

function VariableTimeZone(name::String, transitions::Vector{Transition})
    return VariableTimeZone(symbol(name), transitions)
end

Base.show(io::IO, tz::VariableTimeZone) = print(io, string(tz.name))

immutable ZonedDateTime <: TimeType
    utc_datetime::DateTime
    timezone::TimeZone
    zone::FixedTimeZone  # The current zone for the utc_datetime.
end

"""
Produces a list of possible UTC DateTimes given a local DateTime
and a timezone. Results are returned in ascending order.
"""
function possible_dates(local_dt::DateTime, tz::VariableTimeZone)
    possible = sizehint!(Tuple{DateTime,FixedTimeZone}[], 2)
    t = tz.transitions

    # Determine the earliest and latest possible UTC DateTime
    # that this local DateTime could be.
    # TODO: Maybe look at the range of offsets available within
    # this TimeZone?
    earliest = local_dt - Hour(12)
    latest = local_dt + Hour(14)

    # Determine the earliest transition the local DateTime could
    # occur within.
    i = searchsortedlast(
        t, earliest,
        by=v -> typeof(v) == Transition ? v.utc_datetime : v,
    )
    i = max(i, 1)

    n = length(t)
    while i <= n && t[i].utc_datetime < latest
        utc_dt = local_dt - total_offset(t[i].zone)

        if utc_dt >= t[i].utc_datetime && (i == n || utc_dt < t[i + 1].utc_datetime)
            push!(possible, (utc_dt, t[i].zone))
        end

        i += 1
    end

    return possible
end

function ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, occurrence::Int=0)
    possible = possible_dates(local_dt, tz)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
        # error("Non-existent DateTime")  # NonExistentTimeError
    elseif occurrence > 0
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(local_dt, tz))
        # error("Ambiguous DateTime")  # AmbiguousTimeError
    end
end

# TODO: Need to refactor to make this function possible
function ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, is_dst::Bool)
    possible = possible_dates(local_dt, tz)

    num = length(possible)
    if num == 1
        utc_dt, zone = possible[1]
        return ZonedDateTime(utc_dt, tz, zone)
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
        # error("Non-existent DateTime")  # NonExistentTimeError
    elseif num == 2
        mask = [dst_offset(zone) > Second(0) for (utc_dt, zone) in possible]

        # Mask is expected to be unambiguous.
        !($)(mask...) && throw(AmbiguousTimeError(local_dt, tz))

        occurrence = is_dst ? findfirst(mask) : findfirst(!mask)
        utc_dt, zone = possible[occurrence]
        return ZonedDateTime(utc_dt, tz, zone)
    else
        throw(AmbiguousTimeError(local_dt, tz))
        # error("Ambiguous DateTime")  # AmbiguousTimeError
    end
end

type AmbiguousTimeError <: Exception
    dt::DateTime
    tz::TimeZone
end
Base.showerror(io::IO, e::AmbiguousTimeError) = print(io, "Local DateTime $(e.dt) is ambiguious");

type NonExistentTimeError <: Exception
    dt::DateTime
    tz::TimeZone
end
Base.showerror(io::IO, e::NonExistentTimeError) = print(io, "DateTime $(e.dt) does not exist within $(e.tz)");