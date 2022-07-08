module TZData

using Dates: Dates, DateTime
using LazyArtifacts
using Printf
using ...TimeZones: TZJFile, _scratch_dir

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const ARTIFACT_TOML = joinpath(@__DIR__, "..", "..", "Artifacts.toml")
const LATEST_FILE_PATH = Ref{String}()
const LATEST = Ref{Tuple{AbstractString, DateTime}}()

export REGIONS, LEGACY_REGIONS

function __init__()
    LATEST_FILE_PATH[] = joinpath(_scratch_dir(), "latest")
    if isfile(LATEST_FILE_PATH[])
        LATEST[] = read_latest(LATEST_FILE_PATH[])
    end
end

include("timeoffset.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
