import Base.Dates: now, unix2datetime, Second

DateTime(zdt::ZonedDateTime) = localtime(zdt)
@vectorize_1arg ZonedDateTime DateTime

function now(tz::TimeZone)
    utc = trunc(unix2datetime(time()), Second)
    ZonedDateTime(utc, tz, from_utc=true)
end
