module TZData

using LazyArtifacts
using Printf
using ...TimeZones: DEPS_DIR

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const TZ_SOURCE_DIR = joinpath(DEPS_DIR, "tzsource")
const COMPILED_DIR = joinpath(DEPS_DIR, "compiled", string(VERSION))

const ARTIFACT_TOML = joinpath(@__DIR__, "..", "..", "Artifacts.toml")

export TZ_SOURCE_DIR, COMPILED_DIR, REGIONS, LEGACY_REGIONS

include("timeoffset.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
