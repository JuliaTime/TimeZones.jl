using Mocking

using Artifacts: select_downloadable_artifacts
using Base.BinaryPlatforms: Platform
using RecipesBase
using Test
using TimeZones
using TimeZones: _scratch_dir
using TimeZones.TZData: TZSource, compile, build, tzdata_url, unpack,
    _tz_source_relative_dir, _archive_relative_dir, _compiled_relative_dir
using TZJData: TZJData
using Unicode

Mocking.activate()


const TZDATA_VERSION = "2016j"
const TZFILE_DIR = joinpath(@__DIR__, "tzfile", "data")
const TEST_REGIONS = ["asia", "australasia", "europe", "northamerica"]
const TEST_TZ_SOURCE_DIR = joinpath(_scratch_dir(), _tz_source_relative_dir(TZDATA_VERSION))

# By default use a specific version of tzdata so we just testing for TimeZones.jl code
# changes and not changes to the dataa.
build(TZDATA_VERSION, _scratch_dir())

# For testing we'll reparse the tzdata every time to instead of using the compiled data.
# This should make interactive development/testing cycles simplier since you won't be forced
# to re-build the cache every time you make a change.
#
# Note: resolving only the time zones we want is much faster than running compile which
# recompiles all the time zones.
tzdata = Dict{String,TZSource}()
for name in TEST_REGIONS
    tzdata[name] = TZSource(joinpath(TEST_TZ_SOURCE_DIR, name))
end

include("helpers.jl")

@testset "TimeZones" begin
    include("utils.jl")
    include("indexable_generator.jl")
    include("artifacts.jl")

    include("class.jl")
    include(joinpath("tzdata", "timeoffset.jl"))
    include(joinpath("tzdata", "version.jl"))
    include(joinpath("tzdata", "download.jl"))
    include(joinpath("tzdata", "compile.jl"))
    include(joinpath("tzdata", "build.jl"))
    Sys.iswindows() && include(joinpath("winzone", "WindowsTimeZoneIDs.jl"))
    include("utcoffset.jl")
    include(joinpath("types", "timezone.jl"))
    include(joinpath("types", "fixedtimezone.jl"))
    include(joinpath("types", "variabletimezone.jl"))
    include(joinpath("types", "zoneddatetime.jl"))
    include("exceptions.jl")
    include("interpret.jl")
    include("accessors.jl")
    include("arithmetic.jl")
    include("io.jl")
    include(joinpath("tzfile", "read.jl"))
    include(joinpath("tzfile", "write.jl"))
    include(joinpath("tzjfile", "read.jl"))
    include(joinpath("tzjfile", "write.jl"))
    include("adjusters.jl")
    include("conversions.jl")
    include("ranges.jl")
    include("tz_env.jl")
    include("local.jl")
    include("local_mocking.jl")
    include("discovery.jl")
    include("rounding.jl")
    include("parse.jl")
    include("plotting.jl")
end
