TimeZones.jl
============

[![Linux/OS X Build Status](https://travis-ci.org/quinnj/TimeZones.jl.svg?branch=master)](https://travis-ci.org/quinnj/TimeZones.jl)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/1foo12pca80b5d2j/branch/master?svg=true)](https://ci.appveyor.com/project/omus/timezones-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/quinnj/TimeZones.jl/badge.svg?branch=master)](https://coveralls.io/r/quinnj/TimeZones.jl?branch=master)
[![codecov.io](http://codecov.io/github/quinnj/TimeZones.jl/coverage.svg?branch=master)](http://codecov.io/github/quinnj/TimeZones.jl?branch=master)

Olson Timezone Database Access for the Julia Programming Language

`ZonedDateTime` is *timezone-aware* (in Python parlance) of `DateTime`. All `ZonedDateTime` represented will always be in the correct zone without requiring manual normalization (required by Python's pytz module).

## Usage

To create a `ZonedDateTime` you simply pass in a `DateTime` and a `TimeZone`. Note that `using TimeZones` will generate a couple method definition overwritten warnings which can safely be ignored.

```julia
julia> using TimeZones

julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw

julia> ZonedDateTime(DateTime(2014,1,1), warsaw)
2014-01-01T00:00:00+01:00
```

Working with DateTimes that occur around the "spring forward" transition can result in a `NonExistentTimeError`:

```julia
julia> ZonedDateTime(DateTime(2014,3,30,1), warsaw)
2014-03-30T01:00:00+01:00

julia> ZonedDateTime(DateTime(2014,3,30,2), warsaw)
ERROR: DateTime 2014-03-30T02:00:00 does not exist within Europe/Warsaw
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:126
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:119

julia> ZonedDateTime(DateTime(2014,3,30,3), warsaw)
2014-03-30T03:00:00+02:00
```

Working with DateTimes that occur around the "fall back" transition can result in a `AmbiguousTimeError`. Providing additional parameters can deal with the ambiguity:

```julia
julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw)
ERROR: Local DateTime 2014-10-26T02:00:00 is ambiguious
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:131
 in ZonedDateTime at ~/.julia/v0.4/TimeZones/src/timezones/types.jl:119

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, 1)  # first occurrence of duplicate hour
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, 2)  # second occurrence of duplicate hour
2014-10-26T02:00:00+01:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, true)  # in daylight saving time
2014-10-26T02:00:00+02:00

julia> ZonedDateTime(DateTime(2014,10,26,2), warsaw, false)  # not in daylight saving time
2014-10-26T02:00:00+01:00
```

## TimeType-Period Arithmetic

`ZonedDateTime` use calendrical arithmetic in a [similar manner to `DateTime`](http://julia.readthedocs.org/en/latest/manual/dates/#timetype-period-arithmetic) but with some key differences. Lets look at these differences by adding a day to March 30th 2014 in Europe/Warsaw. 


```julia
julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw

julia> spring = ZonedDateTime(DateTime(2014,3,30), warsaw)
2014-03-30T00:00:00+01:00

julia> spring + Dates.Day(1)
2014-03-31T00:00:00+02:00
```

Adding a day to the `ZonedDateTime` changed the date from the 30th to the 31st as expected. Looking more closely however you'll notice that the timezone offset changed from +01:00 to +02:00. The reason for this change is because Europe/Warsaw switched from standard time (+01:00) to daylight saving time (+02:00) causing the local date 2014-03-31T02:00:00 to be skipped effectively making the day only contain 23 hours. By adding Hours we can see the difference:

```julia
julia> spring + Dates.Hour(23)
2014-03-31T00:00:00+02:00

julia> spring + Dates.Hour(24)
2014-03-31T01:00:00+02:00
```

One potential cause of confusion regarding this behaviour is the loss in associativity. For example:

```julia
julia> (spring + Day(1)) + Hour(24)
2014-04-01T00:00:00+02:00

julia> (spring + Hour(24)) + Day(1)
2014-04-01T01:00:00+02:00

julia> spring + Hour(24) + Day(1)
2014-04-01T00:00:00+02:00
```

Take particular note of the last example which ends up merging the two periods into a single unit of 2 days.

