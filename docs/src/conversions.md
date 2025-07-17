# Conversions

```@meta
DocTestSetup = quote
    using TimeZones, Dates
end
```

## Accessing components of a `ZonedDateTime`

To get a timezone unaware `DateTime` from a `ZonedDateTime`, one can use the `DateTime` constructor.
Passing a single `ZonedDateTime` argument will provide a "local time" `DateTime` while additionally passing in `UTC` as the second argument provide UTC `DateTime` instead.

Note: Some `DateTime` functions implicitly assume UTC, like `Dates.datetime2unix`, which assumes UTC to compute a [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time).

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> DateTime(zdt)
2014-05-30T21:00:00

julia> DateTime(zdt, UTC)
2014-05-31T01:00:00
```

Similar methods exist for `Date` and `Time`:

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Date(zdt)
2014-05-30

julia> Date(zdt, UTC)
2014-05-31

julia> Time(zdt)
21:00:00

julia> Time(zdt, UTC)
01:00:00
```

Similar methods exist for `Date` and `Time`:

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Date(zdt)
2014-05-30

julia> Date(zdt, UTC)
2014-05-31

julia> Time(zdt)
21:00:00

julia> Time(zdt, UTC)
01:00:00
```

You can also use `FixedTimeZone` to access the UTC offset used at the given "local time" and `TimeZone` to access the timezone passed into the `ZonedDateTime` constructor:

```jldoctest
julia> zdt1 = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> FixedTimeZone(zdt1)
EDT (UTC-4)

julia> zdt2 = ZonedDateTime(2014, 2, 18, 6, tz"America/New_York")
2014-02-18T06:00:00-05:00

julia> FixedTimeZone(zdt2)
EST (UTC-5)

julia> TimeZone(zdt1)
America/New_York (UTC-5/UTC-4)
```

## Switching Time Zones

Switching an existing `ZonedDateTime` from one `TimeZone` to another can be done with the function `astimezone`:

```jldoctest
julia> zdt = ZonedDateTime(2014, 1, 1, tz"UTC")
2014-01-01T00:00:00+00:00

julia> astimezone(zdt, tz"Asia/Tokyo")
2014-01-01T09:00:00+09:00
```

## Parsing strings

`ZonedDateTime` parsing extends the functionality provided by `Dates`. If you haven't already it is recommended that you first read the official Julia manual on [Date and DateTime](https://docs.julialang.org/en/v1/stdlib/Dates/#Constructors-1). The `TimeZones` package adds `z` and `Z` to the list of available [parsing character codes](https://docs.julialang.org/en/v1/stdlib/Dates/#Dates.DateFormat):

| Code | Matches              | Comment                                          |
|:-----|:---------------------|:-------------------------------------------------|
| `z`  | +04:00, +0400, UTC+4 | Matches a numeric UTC offset                     |
| `Z`  | Asia/Dubai, UTC      | Matches names of time zones from the TZ database |

Note that with the exception of "UTC" and "GMT" time zone abbrevations cannot be parsed using the `Z` character code since most abbreviations are ambiguous. For example abbreviation "MST" could be interpreted as "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).

Parsing a `ZonedDateTime` just requires the text to parse and a format string:

```jldoctest
julia> ZonedDateTime("20150101-0700", "yyyymmddzzzz")
2015-01-01T00:00:00-07:00

julia> ZonedDateTime("2015-08-06T22:25:31+07:00", "yyyy-mm-ddTHH:MM:SSzzzz")
2015-08-06T22:25:31+07:00
```

When parsing several `ZonedDateTime` strings which use the same format you will see better performance if you first create a `Dates.DateFormat` instead of passing in a raw format string.

```jldoctest
julia> df = Dates.DateFormat("yy-mm-ddz");

julia> ZonedDateTime("2015-03-29+01:00", df)
2015-03-29T00:00:00+01:00

julia> ZonedDateTime("2015-03-30+02:00", df)
2015-03-30T00:00:00+02:00
```

## Formatting strings

Formatting a `ZonedDateTime` as a string also extends the functionality provided by `Base.Dates`. The `TimeZones` package adds the new formatting character codes `z` and `Z` to the list of available [formatting character codes](https://docs.julialang.org/en/v1/stdlib/Dates/#Dates.DateFormat):

| Code | Examples             | Comment                                          |
|:-----|:---------------------|:-------------------------------------------------|
| `z`  | +04:00               | Numeric UTC offset                               |
| `Z`  | GST, UTC             | Time zone abbreviation                           |

It is recommended that you prefer the use of the `z` character code over `Z` time zone abbreviations can be interpreted in different ways.

Formatting uses the `Dates.format` function with a `ZonedDateTime` and a format string:

```jldoctest
julia> zdt = ZonedDateTime(2015, 8, 6, 22, 25, tz"Europe/Warsaw")
2015-08-06T22:25:00+02:00

julia> Dates.format(zdt, "yyyymmddzzzz")
"20150806+02:00"

julia> Dates.format(zdt, "yyyy-mm-dd HH:MM ZZZ")
"2015-08-06 22:25 CEST"
```
