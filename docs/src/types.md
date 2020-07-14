# Time Zone Types

```@meta
DocTestSetup = quote
    using TimeZones, Dates
end
```

```@setup tz
using TimeZones, Dates
```

## TimeZone

A `TimeZone` is an abstract type that represents information regarding a specific time zone. Typically you will create an instance of a `TimeZone` by passing in a zone name to the convenience constructor `TimeZone`:

```jldoctest warsaw
julia> TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)
```

You can also create a `TimeZone` by using a `tz` string macro:

```jldoctest warsaw
julia> tz"Europe/Warsaw"
Europe/Warsaw (UTC+1/UTC+2)
```

To see all of the [currently available](@ref etc_tzs) time zone names:

```@example tz
timezone_names()
nothing; # hide
```

## ZonedDateTime

A `ZonedDateTime` is a *time zone aware* version of a `DateTime` (in Python parlance). Note that all `ZonedDateTime` instances will always be in the correct zone without requiring manual normalization (unlike Python's [pytz](https://pypi.org/project/pytz/) module).

To construct a `ZonedDateTime` instance you just need a `DateTime` and a `TimeZone`:

```jldoctest warsaw
julia> ZonedDateTime(DateTime(2014, 1, 1), tz"Europe/Warsaw")
2014-01-01T00:00:00+01:00

julia> ZonedDateTime(2014, 1, 1, tz"Europe/Warsaw")
2014-01-01T00:00:00+01:00
```

## VariableTimeZone

A `VariableTimeZone` is a concrete type that is a subtype of `TimeZone` that has offsets that change depending on the specified time. We've already seen an example of a `VariableTimeZone`: "Europe/Warsaw"

```jldoctest warsaw
julia> warsaw = tz"Europe/Warsaw"
Europe/Warsaw (UTC+1/UTC+2)

julia> typeof(warsaw)
VariableTimeZone

julia> ZonedDateTime(DateTime(2014, 1, 1), warsaw)
2014-01-01T00:00:00+01:00

julia> ZonedDateTime(DateTime(2014, 6, 1), warsaw)
2014-06-01T00:00:00+02:00
```

From the above example you can see that the offset for this time zone differed based upon the `DateTime` provided. An unfortunate side effect of having the offset change over time results in some difficulties in working with dates near the transitions. For example when working with a `DateTime` that occurs during the "spring forward" transition will result in a `NonExistentTimeError`:

```jldoctest warsaw
julia> ZonedDateTime(DateTime(2014, 3, 30, 1), warsaw)
2014-03-30T01:00:00+01:00

julia> ZonedDateTime(DateTime(2014, 3, 30, 2), warsaw)
ERROR: NonExistentTimeError: Local DateTime 2014-03-30T02:00:00 does not exist within Europe/Warsaw

julia> ZonedDateTime(DateTime(2014, 3, 30, 3), warsaw)
2014-03-30T03:00:00+02:00
```

Alternatively, working with a `DateTime` that occurs during the "fall back" transition results in a `AmbiguousTimeError`. Providing additional parameters can deal with the ambiguity:

```jldoctest warsaw
julia> dt = DateTime(2014,10,26,2)
2014-10-26T02:00:00

julia> ZonedDateTime(dt, warsaw)
ERROR: AmbiguousTimeError: Local DateTime 2014-10-26T02:00:00 is ambiguous within Europe/Warsaw

julia> ZonedDateTime(dt, warsaw, 1)  # first occurrence of the duplicate hour
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(dt, warsaw, 2)  # second occurrence of the duplicate hour
2014-10-26T02:00:00+01:00

julia> ZonedDateTime(dt, warsaw, true)  # use the hour which is in daylight saving time
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(dt, warsaw, false)  # use the hour which is not in daylight saving time
2014-10-26T02:00:00+01:00
```

When working with dates prior to the year 1900 you may notice that the time zone offset includes minutes or even seconds. These kind of offsets are normal:

```jldoctest warsaw
julia> ZonedDateTime(1879, 1, 1, warsaw)
1879-01-01T00:00:00+01:24
```

Alternatively, when using future dates past the year 2038 will result in an error:

```jldoctest warsaw
julia> ZonedDateTime(2039, warsaw)
ERROR: UnhandledTimeError: TimeZone Europe/Warsaw does not handle dates on or after 2038-03-28T01:00:00 UTC
```

It is possible to have [timezones that work beyond 2038](@ref future_tzs) but it since these dates are in the future it is possible the timezone rules may change and will not be accurate.


## FixedTimeZone

A `FixedTimeZone` is a concrete type that is a subtype of `TimeZone` that has a single offset for all of time. An example of this kind of time zone is: "UTC"

```jldoctest
julia> typeof(TimeZone("UTC"))
FixedTimeZone
```

Unlike a `VariableTimeZone` there are no issues with offsets changing over time because with a `FixedTimeZone` the offset never changes. If you need a `FixedTimeZone` that is not provided by the tz database you can manually construct one:

```@example tz
FixedTimeZone("UTC+6")
FixedTimeZone("-0800")
FixedTimeZone("-04:30")
FixedTimeZone("+12:34:56")
FixedTimeZone("FOO", -6 * 3600)  # 6 hours in seconds
nothing; # hide
```

Constructing a `ZonedDateTime` works similarly to `VariableTimeZone`:

```jldoctest
julia> ZonedDateTime(1960, 1, 1, tz"UTC")
1960-01-01T00:00:00+00:00
```
