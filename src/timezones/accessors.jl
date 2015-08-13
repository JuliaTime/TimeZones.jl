offset(tz::FixedTimeZone) = tz.utc_offset + tz.dst_offset

localtime(dt::ZonedDateTime) = dt.utc_datetime + offset(dt.zone)
utc(dt::ZonedDateTime) = dt.utc_datetime

days(dt::ZonedDateTime) = days(localtime(dt))
hour(dt::ZonedDateTime) = hour(localtime(dt))
minute(dt::ZonedDateTime) = minute(localtime(dt))
second(dt::ZonedDateTime) = second(localtime(dt))
millisecond(dt::ZonedDateTime) = millisecond(localtime(dt))
