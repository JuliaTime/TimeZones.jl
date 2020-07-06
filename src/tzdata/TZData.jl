module TZData

using Printf
using Pkg.Artifacts
using ...TimeZones: DEPS_DIR

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const TZ_SOURCE_DIR = joinpath(DEPS_DIR, "tzsource")
const COMPILED_DIR = joinpath(DEPS_DIR, "compiled")

export TZ_SOURCE_DIR, COMPILED_DIR, REGIONS, LEGACY_REGIONS

include("timeoffset.jl")
include("archive.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")
include("deprecated.jl")

end
