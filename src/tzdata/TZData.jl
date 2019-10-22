module TZData

using Printf
using ...TimeZones: DEPS_DIR

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const ARCHIVE_DIR = joinpath(DEPS_DIR, "tzarchive")
const TZ_SOURCE_DIR = joinpath(DEPS_DIR, "tzsource")
const COMPILED_DIR = joinpath(DEPS_DIR, "compiled")

export ARCHIVE_DIR, TZ_SOURCE_DIR, COMPILED_DIR, REGIONS, LEGACY_REGIONS

function __init__()
    if Sys.iswindows()
        if isfile(joinpath(Sys.BINDIR, "7z.exe"))
            global exe7z = joinpath(Sys.BINDIR, "7z.exe")
        else if isfile(joinpath(Sys.BINDIR, "..", "libexec", "7z.exe"))
            # from Julia 1.3 the 7z.exe has moved to this new location
            global exe7z = joinpath(Sys.BINDIR, "..", "libexec", "7z.exe")
        else
            throw("7z.exe not found")
        end
    end
end

include("timeoffset.jl")
include("archive.jl")
include("version.jl")
include("download.jl")
include("compile.jl")
include("build.jl")
include("deprecated.jl")

end
