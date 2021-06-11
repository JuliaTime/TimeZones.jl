module TZData

using Printf
import Dates
import ...TimeZones

import Pkg

if VERSION >= v"1.3"
    using ...TimeZones: @artifact_str
    using Pkg.Artifacts: artifact_hash
end

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

const ARCHIVE_DIR = Ref{String}()
const TZ_SOURCE_DIR = Ref{String}()
const COMPILED_DIR = Ref{String}()
const ACTIVE_VERSION_FILE = Ref{String}()
const LATEST_FILE = Ref{String}()
const LATEST = Ref{Tuple{String, Dates.DateTime}}()

function _init()
    ARCHIVE_DIR[] = joinpath(TimeZones.DEPS_DIR[], "tzarchive")
    TZ_SOURCE_DIR[] = joinpath(TimeZones.DEPS_DIR[], "tzsource")
    COMPILED_DIR[] = joinpath(TimeZones.DEPS_DIR[], "compiled", string(VERSION))
    ACTIVE_VERSION_FILE[] = joinpath(TimeZones.DEPS_DIR[], "active_version")
    LATEST_FILE[] = joinpath(TimeZones.DEPS_DIR[], "latest")

    if isfile(LATEST_FILE[])
        LATEST[] = read_latest(LATEST_FILE[])
    end
end

export ARCHIVE_DIR, TZ_SOURCE_DIR, COMPILED_DIR, REGIONS, LEGACY_REGIONS

if Sys.iswindows()
    if isdefined(Base, :LIBEXECDIR)
        const exe7z = joinpath(Sys.BINDIR, Base.LIBEXECDIR, "7z.exe")
    else
        const exe7z = joinpath(Sys.BINDIR, "7z.exe")
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
