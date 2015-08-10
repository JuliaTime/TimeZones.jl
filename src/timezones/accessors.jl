offset(tz::FixedTimeZone) = tz.utc_offset + tz.dst_offset

localtime(dt::ZonedDateTime) = dt.utc_datetime + offset(dt.zone)
utc(dt::ZonedDateTime) = dt.utc_datetime
