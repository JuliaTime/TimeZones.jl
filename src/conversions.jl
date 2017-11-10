import Compat.Dates: unix2datetime, datetime2unix, julian2datetime, datetime2julian, now

# UTC is an abstract type defined in Dates, for some reason
const utc_tz = FixedTimeZone("UTC")

"""
    DateTime(::ZonedDateTime) -> DateTime

Returns an equivalent `DateTime` without any `TimeZone` information.
"""
DateTime(zdt::ZonedDateTime) = localtime(zdt)

"""
    now(::TimeZone) -> ZonedDateTime

Returns a `ZonedDateTime` corresponding to the user's system time in the specified `TimeZone`.
"""
function now(tz::TimeZone)
    utc = unix2datetime(time())
    ZonedDateTime(utc, tz, from_utc=true)
end

"""
    astimezone(zdt::ZonedDateTime, tz::TimeZone) -> ZonedDateTime

Converts a `ZonedDateTime` from its current `TimeZone` into the specified `TimeZone`.
"""
function astimezone end

function astimezone(zdt::ZonedDateTime, tz::VariableTimeZone)
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

function astimezone(zdt::ZonedDateTime, tz::FixedTimeZone)
    return ZonedDateTime(zdt.utc_datetime, tz, tz)
end

function zdt2julian(zdt::ZonedDateTime)
    datetime2julian(utc(zdt))
end

function zdt2julian(::Type{T}, zdt::ZonedDateTime) where T<:Integer
    floor(T, datetime2julian(utc(zdt)))
end

function zdt2julian(::Type{T}, zdt::ZonedDateTime) where T<:Number
    convert(T, datetime2julian(utc(zdt)))
end

function julian2zdt(jd::Real)
    ZonedDateTime(julian2datetime(jd), utc_tz, from_utc=true)
end

function zdt2unix(zdt::ZonedDateTime)
    datetime2unix(utc(zdt))
end

function zdt2unix(::Type{T}, zdt::ZonedDateTime) where T<:Integer
    floor(T, datetime2unix(utc(zdt)))
end

function zdt2unix(::Type{T}, zdt::ZonedDateTime) where T<:Number
    convert(T, datetime2unix(utc(zdt)))
end

function unix2zdt(seconds::Integer)
    ZonedDateTime(unix2datetime(seconds), utc_tz, from_utc=true)
end
