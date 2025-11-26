module TZData

using Dates: Dates, DateTime
using Printf
using ...TimeZones: TZJFile, _scratch_dir
using TZJData: TZJData
using p7zip_jll: p7zip_jll

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

export REGIONS, LEGACY_REGIONS

const FOO = Ref{String}()
function __init__()
    FOO[] = _scratch_dir()
end

include("timeoffset.jl")
include("version.jl")
include("archive.jl")
include("download.jl")
include("compile.jl")
include("build.jl")
include("deprecated.jl")

end
