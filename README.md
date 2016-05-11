TimeZones.jl
============

[![Linux/OS X Build Status](https://travis-ci.org/quinnj/TimeZones.jl.svg?branch=master)](https://travis-ci.org/quinnj/TimeZones.jl)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/99tm5t4txx92oh2c/branch/master?svg=true)](https://ci.appveyor.com/project/quinnj/timezones-jl/branch/master)
[![codecov.io](http://codecov.io/github/quinnj/TimeZones.jl/coverage.svg?branch=master)](http://codecov.io/github/quinnj/TimeZones.jl?branch=master)
[![TimeZones](http://pkg.julialang.org/badges/TimeZones_0.4.svg)](http://pkg.julialang.org/?pkg=TimeZones&ver=0.4)

[IANA time zone database](http://www.iana.org/time-zones) access for the [Julia](http://julialang.org/) programming language. TimeZones.jl extends the Date/DateTime support for Julia to include a new time zone aware DateTime type: ZonedDateTime.

## Features

* A new time zone aware DateTime type: ZonedDateTime
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
