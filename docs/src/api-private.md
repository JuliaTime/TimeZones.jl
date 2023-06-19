# TimeZones Internal API

## TZData

```@docs
TimeZones.TZData.tzdata_versions
TimeZones.TZData.tzdata_latest_version
TimeZones.TZData.tzdata_version_dir
TimeZones.TZData.tzdata_version_archive
TimeZones.TZData.read_news
TimeZones.TZData.compile!
TimeZones.TZData.tryparse_dayofmonth_function
TimeZones.TZData.order_rules
```

## Interpretation

```@docs
TimeZones.transition_range
TimeZones.interpret
TimeZones.shift_gap
TimeZones.first_valid
TimeZones.last_valid
```

## TZFile

```@docs
TZFile.read
TZFile.write
```

## Etc.

```@docs
TimeZones.UTCOffset
TimeZones.@optional
TimeZones.parse_tz_format
TimeZones.tryparse_tz_format
hash(::ZonedDateTime, ::UInt)
Dates.guess(::ZonedDateTime, ::ZonedDateTime, ::Any)
```
