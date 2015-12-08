import Base.Dates: now, unix2datetime

"""
    DateTime(::ZonedDateTime) -> DateTime

Returns an equivalent `DateTime` without any `TimeZone` information.
"""
DateTime(zdt::ZonedDateTime) = localtime(zdt)
@vectorize_1arg ZonedDateTime DateTime

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
