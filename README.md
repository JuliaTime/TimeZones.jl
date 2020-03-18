TimeZones.jl
============

[![Travis CI](https://travis-ci.org/JuliaTime/TimeZones.jl.svg?branch=master)](https://travis-ci.org/JuliaTime/TimeZones.jl)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/ru96a9u8h83j9ixu/branch/master?svg=true)](https://ci.appveyor.com/project/omus/timezones-jl)
[![codecov](https://codecov.io/gh/JuliaTime/TimeZones.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTime/TimeZones.jl)
<br/>
[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatime.github.io/TimeZones.jl/stable)
[![Dev Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatime.github.io/TimeZones.jl/dev)
<br/>
[![code style blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

[IANA time zone database](http://www.iana.org/time-zones) access for the [Julia](http://julialang.org/) programming language. TimeZones.jl extends the Date/DateTime support for Julia to include a new time zone aware TimeType: ZonedDateTime.

## Features

* A new time zone aware TimeType: ZonedDateTime
* Support for all time zones in the IANA time zone database (also known as the tz/zoneinfo/Olson database)
* ZonedDateTime-Period arithmetic [similar to that of DateTime](https://docs.julialang.org/en/stable/manual/dates/#TimeType-Period-Arithmetic-1)
* Local system time zone information as a TimeZone
* Current system time in any TimeZone
* Support for reading the [tzfile](http://man7.org/linux/man-pages/man5/tzfile.5.html) format
* String parsing of ZonedDateTime using [DateFormat](https://docs.julialang.org/en/stable/stdlib/dates/#Base.Dates.DateFormat)

## Installation

TimeZones.jl can be installed through the Julia package manager:

```julia
julia> Pkg.add("TimeZones")
```

For detailed installation instructions see the documentation linked above.
