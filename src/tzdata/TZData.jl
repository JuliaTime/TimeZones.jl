module TZData

using Printf
import ...TimeZones

import Pkg

if VERSION >= v"1.3"
    using ...TimeZones: @artifact_str
    using Pkg.Artifacts: artifact_hash
end

# Note: The tz database is made up of two parts: code and data. TimeZones.jl only requires
# the "tzdata" archive or more specifically the "tz source" files within the archive
# (africa, australasia, ...)

function _init()
    global ARCHIVE_DIR = joinpath(TimeZones.DEPS_DIR, "tzarchive")
    global TZ_SOURCE_DIR = joinpath(TimeZones.DEPS_DIR, "tzsource")
    global COMPILED_DIR = joinpath(TimeZones.DEPS_DIR, "compiled", string(VERSION))
    global ACTIVE_VERSION_FILE = joinpath(TimeZones.DEPS_DIR, "active_version")
    global LATEST_FILE = joinpath(TimeZones.DEPS_DIR, "latest")

    global LATEST = let T = Tuple{AbstractString, DateTime}
        isfile(LATEST_FILE) ? Ref{T}(read_latest(LATEST_FILE)) : Ref{T}()
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
