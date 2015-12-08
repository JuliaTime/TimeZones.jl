Time Zones
==========

[TimeZones.jl](https://github.com/quinnj/TimeZones.jl) provides access to the Olson timezone database to the programming language [Julia](http://julialang.org/). This library can handle any Olson timezone but some timezones have excluded by default due to them being deemed as historical (such as "Etc/*").

# Installation Guide

The TimeZones package extends the Dates module provided by Julia version 0.4. In order to use this package you will need to have Julia 0.4 or higher installed on your system. Details on downloading and installing Julia can be found on the [language homepage](http://julialang.org/).

Once Julia is installed you can simply install TimeZones using the package manager. First open a Julia interactive session and run:

```julia
Pkg.add("TimeZones")
```

This command will install the latest version of TimeZones, automatically download the latest Olson timezone information, and pre-process the data into an optimized format.

Sometimes the IANA server where we get the Olson timezone information is inaccessible. If this occurs you'll see an error similar to:

```julia
ERROR: Missing region file northamerica. Unable to download: ftp://ftp.iana.org/tz/data/northamerica
```

To correct this problem try to downloading the Olson data at a later time. You can trigger a download again with:

```julia
Pkg.build("TimeZones")
```
