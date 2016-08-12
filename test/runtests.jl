using Mocking
Mocking.enable()

using Base.Test
using TimeZones
import TimeZones: PKG_DIR, TZDATA_DIR
import TimeZones.Olson: ZoneDict, RuleDict, tzparse, resolve

const TZFILE_DIR = joinpath(PKG_DIR, "test", "tzfile")

# For testing we'll reparse the tzdata every time to instead of using the serialized data.
# This should make the development/testing cycle simplier since you won't be forced to
# re-build the cache every time you make a change.
#
# Note: resolving only the time zones we want is much faster than running compile which
# recompiles all the time zones.
tzdata = Dict{AbstractString,Tuple{ZoneDict,RuleDict}}()
for name in ("asia", "australasia", "europe", "northamerica")
    tzdata[name] = tzparse(joinpath(TZDATA_DIR, name))
end

include("utils.jl")
include("time.jl")
include("Olson.jl")
include("utcoffset.jl")
include("types.jl")
include("interpret.jl")
include("accessors.jl")
include("arithmetic.jl")
include("io.jl")
include("tzfile.jl")
include("adjusters.jl")
include("conversions.jl")
include("ranges.jl")
include("local.jl")
include("local_mocking.jl")
include("discovery.jl")
VERSION >= v"0.5.0-dev+5244" && include("rounding.jl")
include("TimeZones.jl")
