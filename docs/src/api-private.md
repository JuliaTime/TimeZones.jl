# TimeZones Internal API

```@meta
DocTestSetup = quote
    using TimeZones
end
```

## TZData

```@docs
TimeZones.TZData.tzdata_url
TimeZones.TZData.tzdata_download
TimeZones.TZData.isarchive
TimeZones.TZData.readarchive
TimeZones.TZData.extract
TimeZones.TZData.tzdata_version_dir
TimeZones.TZData.tzdata_version_archive
TimeZones.TZData.read_news
TimeZones.TZData.compile!
TimeZones.TZData.tryparse_dayofmonth
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

## Etc.

```@docs
TimeZones.UTCOffset
TimeZones.@optional
TimeZones.read_tzfile
TimeZones.parse_tz_format
hash(::ZonedDateTime, ::UInt)
Dates.guess(::ZonedDateTime, ::ZonedDateTime, ::Any)
```