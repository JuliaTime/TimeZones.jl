TimeZones.jl
============

[![TimeZones](http://pkg.julialang.org/badges/TimeZones_0.4.svg)](http://pkg.julialang.org/?pkg=TimeZones)
[![TimeZones](http://pkg.julialang.org/badges/TimeZones_0.5.svg)](http://pkg.julialang.org/?pkg=TimeZones)
[![TimeZones](http://pkg.julialang.org/badges/TimeZones_0.6.svg)](http://pkg.julialang.org/?pkg=TimeZones)
<br/>
[![Linux/OS X Build Status](https://travis-ci.org/JuliaTime/TimeZones.jl.svg?branch=master)](https://travis-ci.org/JuliaTime/TimeZones.jl)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/ru96a9u8h83j9ixu/branch/master?svg=true)](https://ci.appveyor.com/project/omus/timezones-jl)
[![codecov](https://codecov.io/gh/JuliaTime/TimeZones.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTime/TimeZones.jl)

[IANA time zone database](http://www.iana.org/time-zones) access for the [Julia](http://julialang.org/) programming language. TimeZones.jl extends the Date/DateTime support for Julia to include a new time zone aware TimeType: ZonedDateTime.

## Features

* A new time zone aware TimeType: ZonedDateTime
* Support for all time zones in the IANA time zone database (also known as the tz/zoneinfo/Olson database)
* ZonedDateTime-Period arithmetic [similar to that of DateTime](http://julia.readthedocs.io/en/latest/manual/dates/#timetype-period-arithmetic)
* Local system time zone information as a TimeZone
* Current system time in any TimeZone
* Support for reading the [tzfile](http://man7.org/linux/man-pages/man5/tzfile.5.html) format
* String parsing of ZonedDateTime using [DateFormat](http://julia.readthedocs.org/en/latest/manual/dates/?highlight=dateformat#constructors)

## Documentation

Detailed documentation is available for:
* [Latest Release](http://timezonesjl.readthedocs.org/en/stable/)
* [Development](http://timezonesjl.readthedocs.org/en/latest/)

## Installation

TimeZones.jl can be installed through the Julia package manager:

```julia
julia> Pkg.add("TimeZones")
```

For detailed installation instructions see the documentation linked above.
