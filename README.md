TimeZones.jl
============

[![Linux/OS X Build Status](https://travis-ci.org/quinnj/TimeZones.jl.svg?branch=master)](https://travis-ci.org/quinnj/TimeZones.jl)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/99tm5t4txx92oh2c/branch/master?svg=true)](https://ci.appveyor.com/project/quinnj/timezones-jl/branch/master)
[![codecov.io](http://codecov.io/github/quinnj/TimeZones.jl/coverage.svg?branch=master)](http://codecov.io/github/quinnj/TimeZones.jl?branch=master)
[![TimeZones](http://pkg.julialang.org/badges/TimeZones_0.4.svg)](http://pkg.julialang.org/?pkg=TimeZones&ver=0.4)

Olson Timezone Database access for the Julia Programming Language. TimeZones.jl extends the DateTime support for Julia to include a new timezone-aware DateTime: ZonedDateTime.

## Features

* Timezone-aware DateTime: ZonedDateTime
* Support for Olson database time zones
* ZonedDateTime-Period arithmetic similar to that of DateTime
* Local system TimeZone
* Current time in any TimeZone
* Support for reading [tzfile](http://man7.org/linux/man-pages/man5/tzfile.5.html)
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
