module TZData

using LazyArtifacts
using Printf
using ...TimeZones: TZJFile, scratch_dir

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

tz_source_dir() = scratch_dir("tzsource")

# By including the default tzjfile version in the directory structure we can support having
# multiple tzjfile file versions co-existing. Ideally the version specified here would be
# tied in someway to the version produced by `compile` in a more explicit manner.
compiled_dir() = scratch_dir("compiled", "tzjf", "v$(TZJFile.DEFAULT_VERSION)")

const ARTIFACT_TOML = joinpath(@__DIR__, "..", "..", "Artifacts.toml")

export REGIONS, LEGACY_REGIONS

include("timeoffset.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
