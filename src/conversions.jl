using Dates: unix2datetime, datetime2unix, julian2datetime, datetime2julian
using Mocking: Mocking, @mock

# UTC is an abstract type defined in Dates, for some reason
const utc_tz = FixedTimeZone("UTC")


"""
    now(::TimeZone) -> ZonedDateTime

Create a `ZonedDateTime` corresponding to the current system time in the specified `TimeZone`.

See also: [`today(::TimeZone)`](@ref), [`todayat(::TimeZone)`](@ref).
"""
function Dates.now(tz::TimeZone)
    utc = unix2datetime(time())
    ZonedDateTime(utc, tz, from_utc=true)
end

"""
    today(tz::TimeZone) -> Date

Create the current `Date` in the specified `TimeZone`. Equivalent to `Date(now(tz))`.

See also: [`now(::TimeZone)`](@ref), [`todayat(::TimeZone)`](@ref).

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
Dates.today(tz::TimeZone) = Date(now(tz))

"""
    todayat(tod::Time, tz::TimeZone, [amb::Union{Integer,Bool}]) -> ZonedDateTime

Creates a `ZonedDateTime` for today at the specified time of day. If the result is ambiguous
in the given `TimeZone` then `amb` can be supplied to resolve ambiguity.

See also: [`now(::TimeZone)`](@ref), [`today(::TimeZone)`](@ref).

# Examples

```julia
julia> today(tz"Europe/Warsaw")
2017-10-29

julia> todayat(Time(10, 30), tz"Europe/Warsaw")
2017-10-29T10:30:00+01:00

julia> todayat(Time(2), tz"Europe/Warsaw")
ERROR: AmbiguousTimeError: Local DateTime 2017-10-29T02:00:00 is ambiguous within Europe/Warsaw

julia> todayat(Time(2), tz"Europe/Warsaw", 1)
2017-10-29T02:00:00+02:00

julia> todayat(Time(2), tz"Europe/Warsaw", 2)
2017-10-29T02:00:00+01:00
```
"""
function todayat(tod::Time, tz::VariableTimeZone, amb::Union{Integer,Bool})
    ZonedDateTime((@mock today(tz)) + tod, tz, amb)
end

todayat(tod::Time, tz::TimeZone) = ZonedDateTime((@mock today(tz)) + tod, tz)


"""
    astimezone(zdt::ZonedDateTime, tz::TimeZone) -> ZonedDateTime

Converts a `ZonedDateTime` from its current `TimeZone` into the specified `TimeZone`.
"""
function astimezone end

function astimezone(zdt::ZonedDateTime, tz::VariableTimeZone)
    i = searchsortedlast(
        tz.transitions, zdt.utc_datetime,
        by=v -> v isa Transition ? v.utc_datetime : v,
    )

    if i == 0
        throw(NonExistentTimeError(DateTime(zdt), tz))
    end

    zone = tz.transitions[i].zone
    return ZonedDateTime(zdt.utc_datetime, tz, zone)
end

function astimezone(zdt::ZonedDateTime, tz::FixedTimeZone)
    return ZonedDateTime(zdt.utc_datetime, tz, tz)
end

function zdt2julian(zdt::ZonedDateTime)
    datetime2julian(DateTime(zdt, UTC))
end

function zdt2julian(::Type{T}, zdt::ZonedDateTime) where T<:Integer
    floor(T, datetime2julian(DateTime(zdt, UTC)))
end

function zdt2julian(::Type{T}, zdt::ZonedDateTime) where T<:Real
    convert(T, datetime2julian(DateTime(zdt, UTC)))
end

function julian2zdt(jd::Real)
    ZonedDateTime(julian2datetime(jd), utc_tz, from_utc=true)
end

function zdt2unix(zdt::ZonedDateTime)
    datetime2unix(DateTime(zdt, UTC))
end

function zdt2unix(::Type{T}, zdt::ZonedDateTime) where T<:Integer
    floor(T, datetime2unix(DateTime(zdt, UTC)))
end

function zdt2unix(::Type{T}, zdt::ZonedDateTime) where T<:Real
    convert(T, datetime2unix(DateTime(zdt, UTC)))
end

function unix2zdt(seconds::Real)
    ZonedDateTime(unix2datetime(seconds), utc_tz, from_utc=true)
end
