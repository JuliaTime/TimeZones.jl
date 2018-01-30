module TZData

using Compat
using Compat: @info, @warn
using Compat.Printf
using Nullables

# https://github.com/JuliaLang/Compat.jl/pull/473
if VERSION < v"0.7.0-DEV.3476"
    using Base.Serializer
else
    using Serialization
end

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

export build

include("timeoffset.jl")
include("archive.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
