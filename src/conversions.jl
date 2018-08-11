import Compat.Dates: unix2datetime, datetime2unix, julian2datetime, datetime2julian,
    now, today
using Mocking

# UTC is an abstract type defined in Dates, for some reason
const utc_tz = FixedTimeZone("UTC")

"""
    DateTime(::Localized) -> DateTime

Returns an equivalent `DateTime` without any `TimeZone` information.
"""
DateTime(zdt::Localized) = localtime(zdt)

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
    astimezone(zdt::Localized, tz::TimeZone) -> Localized

Converts a `Localized` from its current `TimeZone` into the specified `TimeZone`.
"""
function astimezone end

function astimezone(zdt::Localized, tz::VariableTimeZone)
    i = searchsortedlast(
        tz.transitions, zdt.utc_datetime,
        by=v -> typeof(v) == Transition ? v.utc_datetime : v,
    )

    if i == 0
        throw(NonExistentTimeError(localtime(zdt), tz))
    end

    zone = tz.transitions[i].zone
    return Localized(zdt.utc_datetime, tz, zone)
end

function astimezone(zdt::Localized, tz::FixedTimeZone)
    return Localized(zdt.utc_datetime, tz, tz)
end

function zdt2julian(zdt::Localized)
    datetime2julian(utc(zdt))
end

function zdt2julian(::Type{T}, zdt::Localized) where T<:Integer
    floor(T, datetime2julian(utc(zdt)))
end

function zdt2julian(::Type{T}, zdt::Localized) where T<:Real
    convert(T, datetime2julian(utc(zdt)))
end

function julian2zdt(jd::Real)
    Localized(julian2datetime(jd), utc_tz, from_utc=true)
end

function zdt2unix(zdt::Localized)
    datetime2unix(utc(zdt))
end

function zdt2unix(::Type{T}, zdt::Localized) where T<:Integer
    floor(T, datetime2unix(utc(zdt)))
end

function zdt2unix(::Type{T}, zdt::Localized) where T<:Real
    convert(T, datetime2unix(utc(zdt)))
end

function unix2zdt(seconds::Real)
    Localized(unix2datetime(seconds), utc_tz, from_utc=true)
end
