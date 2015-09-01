Second(offset::Offset) = offset.utc + offset.dst

localtime(dt::ZonedDateTime) = dt.utc_datetime + Second(dt.zone.offset)
utc(dt::ZonedDateTime) = dt.utc_datetime

days(dt::ZonedDateTime) = days(localtime(dt))
hour(dt::ZonedDateTime) = hour(localtime(dt))
minute(dt::ZonedDateTime) = minute(localtime(dt))
second(dt::ZonedDateTime) = second(localtime(dt))
millisecond(dt::ZonedDateTime) = millisecond(localtime(dt))
