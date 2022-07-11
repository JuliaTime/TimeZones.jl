module TZData

using Dates: Dates, DateTime
using LazyArtifacts: @artifact_str, artifact_hash
using Printf
using ...TimeZones: TZJFile, _scratch_dir

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const ARTIFACT_TOML = joinpath(@__DIR__, "..", "..", "Artifacts.toml")

const _LATEST_FILE_PATH = Ref{String}()
const _LATEST = Ref{Tuple{AbstractString, DateTime}}()

export REGIONS, LEGACY_REGIONS

function __init__()
    _LATEST_FILE_PATH[] = joinpath(_scratch_dir(), "latest")
    if isfile(_LATEST_FILE_PATH[])
        _LATEST[] = read_latest(_LATEST_FILE_PATH[])
    end
end

include("timeoffset.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
