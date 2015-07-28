
# import Base.Dates: UTInstant, DateTime, TimeZone, Millisecond
using Base.Dates

# Using type Symbol instead of AbstractString for name since it
# gets us ==, and hash for free.

# Note: The Olsen Database rounds offset precision to the nearest second
# See "America/New_York" notes for an example.
immutable FixedTimeZone <: TimeZone
    name::Symbol
    offset::Second
end

FixedTimeZone(name::String, offset::Int) = FixedTimeZone(symbol(name), Second(offset))

immutable Transition
    utc_datetime::DateTime  # Instant where new zone applies
    zone::FixedTimeZone
end

Base.isless(x::Transition,y::Transition) = isless(x.utc_datetime,y.utc_datetime)

# function Base.string(t::Transition)
#     return "$(t.utc_datetime), $(t.zone.name), $(t.zone.offset)"
# end

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
        utc_dt = local_dt - t[i].zone.offset

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
# function ZonedDateTime(local_dt::DateTime, tz::VariableTimeZone, is_dst::Bool)
# end

function Base.string(dt::ZonedDateTime)
    offset = dt.zone.offset

    v = offset.value
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    hh = @sprintf("%+03i", h)
    mm = lpad(m, 2, "0")
    ss = s != 0 ? lpad(s, 2, "0") : ""

    local_dt = dt.utc_datetime + offset
    return "$local_dt$hh:$mm$(ss)"
end
Base.show(io::IO,dt::ZonedDateTime) = print(io,string(dt))

utc_datetime(dt::ZonedDateTime) = dt.utc_datetime
local_datetime(dt::ZonedDateTime) = dt.utc_datetime + dt.zone.offset


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