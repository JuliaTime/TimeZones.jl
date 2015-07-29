utc_offset(tz::OffsetTimeZone) = tz.offset
utc_offset(tz::DaylightSavingTimeZone) = tz.utc_offset

dst_offset(tz::OffsetTimeZone) = Second(0)
dst_offset(tz::DaylightSavingTimeZone) = tz.dst_offset

total_offset(tz::OffsetTimeZone) = tz.offset
total_offset(tz::DaylightSavingTimeZone) = tz.utc_offset + tz.dst_offset

# as_utc(dt::ZonedDateTime) = dt.utc_datetime
# as_local(dt::ZonedDateTime) = dt.utc_datetime + offset(dt.zone)
