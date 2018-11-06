# Time Zones

[TimeZones.jl](https://github.com/JuliaTime/TimeZones.jl) provides access to the [IANA time zone database](https://www.iana.org/time-zones) (also referred to as the tz database) to the programming language [Julia](https://julialang.org/). This library can handle any time zone in the tz database but some have excluded by default due to them being deemed as historical (such as "Etc/*").

## Installation

The TimeZones package extends the Dates module provided by Julia version 0.4. In order to use this package you will need to have Julia 0.4 or higher installed on your system. Details on downloading and installing Julia can be found on the [language homepage](https://julialang.org/).

Once Julia is installed you can simply install TimeZones using the package manager. First open a Julia interactive session and run:

```julia-repl
julia> using Pkg  # on Julia 0.7+

julia> Pkg.add("TimeZones")
```

This command will install the latest version of TimeZones, automatically download the latest tz database, and convert the data into an Julia optimized format.
