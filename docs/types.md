## TimeZone

A `TimeZone` is an abstract type that represents information regarding a specific time zone. Typically you will create an instance of a `TimeZone` by passing in a zone name to the convenience constructor `TimeZone`:

```julia
TimeZone("Europe/Warsaw")
```

To see all of the [currently available](/faq/#why-are-the-etc-timezones-unsupported) time zone names:

```julia
timezone_names()
```

## ZonedDateTime

A `ZonedDateTime` is a *timezone-aware* version of a `DateTime` (in Python parlance). Note that all `ZonedDateTime` instances will always be in the correct zone without requiring manual normalization (unlike Python's pytz module).

To construct a `ZonedDateTime` instance you just need a `DateTime` and a `TimeZone`:

```julia
julia> ZonedDateTime(DateTime(2014,1,1), TimeZone("Europe/Warsaw"))
2014-01-01T00:00:00+01:00
```

## VariableTimeZone

A `VariableTimeZone` is a concrete type that is a subtype of `TimeZone` that has offsets that change depending on the specified time. We've already seen an example of a `VariableTimeZone`: "Europe/Warsaw"

```julia
julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw

julia> typeof(warsaw)
TimeZones.VariableTimeZone

julia> ZonedDateTime(DateTime(2014,1,1), warsaw)
2014-01-01T00:00:00+01:00

julia> ZonedDateTime(DateTime(2014,6,1), warsaw)
2014-06-01T00:00:00+02:00
```

From the above example you can see that the offset for this time zone differed based upon the `DateTime` provided. An unfortunate side effect of having the offset change over time results in some difficulties in working with dates near the transitions. For example when working with a `DateTime` that occurs during the "spring forward" transition will result in a `NonExistentTimeError`:

```julia
julia> ZonedDateTime(DateTime(2014,3,30,1), warsaw)
2014-03-30T01:00:00+01:00

julia> ZonedDateTime(DateTime(2014,3,30,2), warsaw)
ERROR: DateTime 2014-03-30T02:00:00 does not exist within Europe/Warsaw
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:184
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:177

julia> ZonedDateTime(DateTime(2014,3,30,3), warsaw)
2014-03-30T03:00:00+02:00
```

Alternatively, working with a `DateTime` that occurs during the "fall back" transition results in a `AmbiguousTimeError`. Providing additional parameters can deal with the ambiguity:

```julia
julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw)
ERROR: Local DateTime 2014-10-26T02:00:00 is ambiguious
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:189
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:177

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, 1)  # use the first occurrence of the duplicate hour
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, 2)  # use second occurrence of the duplicate hour
2014-10-26T02:00:00+01:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, true)  # use the hour which is in daylight saving time
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, false)  # use the hour which is not in daylight saving time
2014-10-26T02:00:00+01:00
```

When working with dates prior to the year 1900 you may notice that the time zone offset includes minutes or even seconds. These kind of offsets are normal:

```julia
julia> ZonedDateTime(DateTime(1879,1,1), warsaw)
1879-01-01T00:00:00+01:24
```

Alternatively, when using future dates past the year 2037 will result in an error:

```julia
julia> ZonedDateTime(DateTime(2038,1,1), warsaw)
ERROR: DateTime exceeds maximum supported by this timezone. Please update the timezone to include transitions past 2037.
```

It is possible to have [timezones that work after 2037](faq/#why-do-some-timezones-only-work-up-to-the-year-2037) but it since these dates are in the future there is no guarantee that the transitions will actually occur on dates provided by TimeZones.jl.


## FixedTimeZone

A `FixedTimeZone` is a concrete type that is a subtype of `TimeZone` that has a single offset for all of time. An example of this kind of time zone is: "UTC"

```julia
julia> typeof(TimeZone("UTC"))
TimeZones.FixedTimeZone
```

Unlike a `VariableTimeZone` there are no issues with offsets changing over time because with a `FixedTimeZone` the offset never changes. If you need a `FixedTimeZone` that is not provided by the Olson database you can manually construct one:

```julia
FixedTimeZone("UTC+6")
FixedTimeZone("-0800")
FixedTimeZone("-04:30")
FixedTimeZone("+12:34:56")
FixedTimeZone("FOO", -6 * 3600)  # 6 hours in seconds
```

Constructing a `ZonedDateTime` works similarly to `VariableTimeZone`:

```julia
julia> ZonedDateTime(DateTime(1960,1,1), TimeZone("UTC"))
1960-01-01T00:00:00+00:00
```
