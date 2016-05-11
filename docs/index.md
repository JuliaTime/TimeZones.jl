Time Zones
==========

[TimeZones.jl](https://github.com/quinnj/TimeZones.jl) provides access to the [IANA time zone database](http://www.iana.org/time-zones) (also referred to as the tz database) to the programming language [Julia](http://julialang.org/). This library can handle any time zone in the tz database but some have excluded by default due to them being deemed as historical (such as "Etc/*").

# Installation

The TimeZones package extends the Dates module provided by Julia version 0.4. In order to use this package you will need to have Julia 0.4 or higher installed on your system. Details on downloading and installing Julia can be found on the [language homepage](http://julialang.org/).

Once Julia is installed you can simply install TimeZones using the package manager. First open a Julia interactive session and run:

```julia
julia> Pkg.add("TimeZones")
```

This command will install the latest version of TimeZones, automatically download the latest tz database, and convert the data into an Julia optimized format.

Sometimes the official server where we get the tz database is inaccessible. If this occurs you'll see an error similar to:

```julia
ERROR: Unable to download tz database
```

To correct this problem try to downloading the tz database at a later time. You can trigger a download again with:

```julia
julia> Pkg.build("TimeZones")
```
