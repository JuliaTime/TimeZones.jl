## Switching Time Zones

Switching an existing `ZonedDateTime` from one `TimeZone` to another can be done with the constructor `ZonedDateTime(::ZonedDateTime, ::TimeZone)`:

```julia
julia> zdt = ZonedDateTime(2014, 1, 1, TimeZone("UTC"))
2014-01-01T00:00:00+00:00

julia> ZonedDateTime(zdt, TimeZone("Asia/Tokyo"))
2014-01-01T09:00:00+09:00
```

## Parsing strings

`ZonedDateTime` parsing extends the functionality provided by `Base.Dates`. If you haven't already it is recommended that you first read the official Julia manual on [Date and DateTime](http://julia.readthedocs.io/en/latest/manual/dates/#constructors). The `TimeZones` package adds `z` and `Z` to the list of available [parsing character codes](http://julia.readthedocs.io/en/latest/stdlib/dates/#man-date-parsing):

| Code | Matches              | Comment                                          |
|:-----|:---------------------|:-------------------------------------------------|
| `z`  | +04:00, +0400, UTC+4 | Matches a numeric UTC offset                     |
| `Z`  | Asia/Dubai, UTC      | Matches names of time zones from the TZ database |

Note that with the exception of "UTC" and "GMT" time zone abbrevations cannot be parsed using the `Z` character code since most abbreviations are ambiguous. For example abbreviation "MST" could be interpreted as "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).

Parsing a `ZonedDateTime` just requires the text to parse and a format string:

```julia
julia> ZonedDateTime("20150101-0700", "yyyymmddzzzz")
2015-01-01T00:00:00-07:00

julia> ZonedDateTime("2015-08-06T22:25:31+07:00", "yyyy-mm-ddTHH:MM:SSzzzz")
2015-08-06T22:25:31+07:00
```

When parsing several `ZonedDateTime` strings which use the same format you will see better performance if you first create a `Dates.DateFormat` instead of passing in a raw format string.

```julia
julia> df = Dates.DateFormat("yy-mm-ddz");

julia> ZonedDateTime("2015-03-29+01:00", df)
2015-03-29T00:00:00+01:00

julia> ZonedDateTime("2015-03-30+02:00", df)
2015-03-30T00:00:00+02:00
```

## Formatting strings

Formatting a `ZonedDateTime` as a string also extends the functionality provided by `Base.Dates`. The `TimeZones` package adds the new formatting character codes `z` and `Z` to the list of available [formatting character codes](http://julia.readthedocs.io/en/latest/stdlib/dates/#man-date-formatting):

| Code | Examples             | Comment                                          |
|:-----|:---------------------|:-------------------------------------------------|
| `z`  | +04:00               | Numeric UTC offset                               |
| `Z`  | GST, UTC             | Time zone abbreviation                           |

It is recommended that you prefer the use of the `z` character code over `Z` time zone abbreviations can be interpreted in different ways.

Formatting uses the `Dates.format` function with a `ZonedDateTime` and a format string:

```julia
julia> zdt = ZonedDateTime(2015,8,6,22,25,TimeZone("Europe/Warsaw"))
2015-08-06T22:25:00+02:00

julia> Dates.format(zdt, "yyyymmddzzzz")
"20150806+02:00"

julia> julia> Dates.format(zdt, "yyyy-mm-dd HH:MM ZZZ")
"2015-08-06 22:25 CEST"
```
