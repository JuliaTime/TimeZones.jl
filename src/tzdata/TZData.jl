module TZData

using LazyArtifacts
using Printf
using ...TimeZones: scratch_dir

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

tz_source_dir() = scratch_dir("tzsource")
compiled_dir() = scratch_dir("serialized", string(VERSION))

const ARTIFACT_TOML = joinpath(@__DIR__, "..", "..", "Artifacts.toml")

export REGIONS, LEGACY_REGIONS

include("timeoffset.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
