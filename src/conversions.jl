import Compat.Dates: unix2datetime, datetime2unix, julian2datetime, datetime2julian,
    now, today
using Mocking

# UTC is an abstract type defined in Dates, for some reason
const utc_tz = FixedTimeZone("UTC")

"""
    DateTime(::Localized) -> DateTime

Returns an equivalent `DateTime` without any `TimeZone` information.
"""
DateTime(ldt::Localized) = localtime(ldt)

"""
    now(::TimeZone) -> Localized

Returns a `Localized` corresponding to the user's system time in the specified `TimeZone`.
"""
function now(tz::TimeZone)
    utc = unix2datetime(time())
    Localized(utc, tz, from_utc=true)
end

"""
    today(tz::TimeZone) -> Date

Returns the date portion of `now(tz)` in local time.

# Examples

```julia
julia> a, b = now(tz"Pacific/Midway"), now(tz"Pacific/Apia")
(2017-11-09T03:47:04.226-11:00, 2017-11-10T04:47:04.226+14:00)

julia> a - b
0 milliseconds

julia> today(tz"Pacific/Midway"), today(tz"Pacific/Apia")
(2017-11-09, 2017-11-10)
```
"""
today(tz::TimeZone) = Date(localtime(now(tz)))

"""
    todayat(tod::Time, tz::TimeZone, [amb]) -> Localized

Creates a `Localized` for today at the specified time of day. If the result is ambiguous
in the given `TimeZone` then `amb` can be supplied to resolve ambiguity.

# Examples

```julia
julia> today(tz"Europe/Warsaw")
2017-11-09

julia> todayat(Time(10, 30), tz"Europe/Warsaw")
2017-11-09T10:30:00+01:00
```
"""
function todayat(tod::Time, tz::VariableTimeZone, amb::Union{Integer,Bool})
    Localized((@mock today(tz)) + tod, tz, amb)
end

todayat(tod::Time, tz::TimeZone) = Localized((@mock today(tz)) + tod, tz)


"""
    astimezone(ldt::Localized, tz::TimeZone) -> Localized

Converts a `Localized` from its current `TimeZone` into the specified `TimeZone`.
"""
function astimezone end

function astimezone(ldt::Localized, tz::VariableTimeZone)
    i = searchsortedlast(
        tz.transitions, ldt.utc_datetime,
        by=v -> typeof(v) == Transition ? v.utc_datetime : v,
    )

    if i == 0
        throw(NonExistentTimeError(localtime(ldt), tz))
    end

    zone = tz.transitions[i].zone
    return Localized(ldt.utc_datetime, tz, zone)
end

function astimezone(ldt::Localized, tz::FixedTimeZone)
    return Localized(ldt.utc_datetime, tz, tz)
end

"""
    restrict(ldt::Localized) -> Localized

Return a restricted representation of the localized datetime or throws an error if that
isn't possible.
"""
restrict(ldt::Localized) = Localized(ldt.utc_datetime, ldt.timezone, ldt.zone, true)

"""
    relax(ldt::Localized) -> Localized

Return a relaxed representation of the localized datetime.
"""
relax(ldt::Localized) = Localized(ldt.utc_datetime, ldt.timezone, ldt.zone, false)

function localized2julian(ldt::Localized)
    datetime2julian(utc(ldt))
end

function localized2julian(::Type{T}, ldt::Localized) where T<:Integer
    floor(T, datetime2julian(utc(ldt)))
end

function localized2julian(::Type{T}, ldt::Localized) where T<:Real
    convert(T, datetime2julian(utc(ldt)))
end

function julian2localized(jd::Real)
    Localized(julian2datetime(jd), utc_tz, from_utc=true)
end

function localized2unix(ldt::Localized)
    datetime2unix(utc(ldt))
end

function localized2unix(::Type{T}, ldt::Localized) where T<:Integer
    floor(T, datetime2unix(utc(ldt)))
end

function localized2unix(::Type{T}, ldt::Localized) where T<:Real
    convert(T, datetime2unix(utc(ldt)))
end

function unix2localized(seconds::Real)
    Localized(unix2datetime(seconds), utc_tz, from_utc=true)
end

Base.convert(::Type{Localized{T, false}}, x::Localized{T, true}) where T = relax(x)
Base.convert(::Type{Localized{T, true}}, x::Localized{T, false}) where T = restrict(x)