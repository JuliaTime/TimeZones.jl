module TZData

using Compat
using Compat: occursin, @info, @warn
import Compat: Sys
using Compat.Printf
using Nullables

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

export build

function __init__()
    if Sys.iswindows()
        global exe7z = joinpath(Sys.BINDIR, "7z.exe")
    end
end

include("timeoffset.jl")
include("archive.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")

end
