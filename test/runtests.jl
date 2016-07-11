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
for name in ("australasia", "europe", "northamerica")
    tzdata[name] = tzparse(joinpath(TZDATA_DIR, name))
end

include(joinpath("timezones", "utils.jl"))
include(joinpath("timezones", "time.jl"))
include(joinpath("timezones", "Olson.jl"))
include(joinpath("timezones", "utcoffset.jl"))
include(joinpath("timezones", "types.jl"))
include(joinpath("timezones", "accessors.jl"))
include(joinpath("timezones", "arithmetic.jl"))
include(joinpath("timezones", "io.jl"))
include(joinpath("timezones", "tzfile.jl"))
include(joinpath("timezones", "adjusters.jl"))
include(joinpath("timezones", "conversions.jl"))
include(joinpath("timezones", "ranges.jl"))
include(joinpath("timezones", "local.jl"))
include(joinpath("timezones", "local_mocking.jl"))
include(joinpath("timezones", "discovery.jl"))
VERSION >= v"0.5.0-dev+5244" && include(joinpath("timezones", "rounding.jl"))
include("TimeZones.jl")
