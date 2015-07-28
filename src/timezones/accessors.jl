tzoffset(tz::OffsetTimeZone) = tz.offset
tzoffset(tz::DaylightSavingTimeZone) = tz.utc_offset + tz.dst_offset

# as_utc(dt::ZonedDateTime) = dt.utc_datetime
# as_local(dt::ZonedDateTime) = dt.utc_datetime + offset(dt.zone)
