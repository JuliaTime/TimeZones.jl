using TimeZones
using Base.Test

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

include("timezones/utils.jl")
include("timezones/time.jl")
include("timezones/Olson.jl")
include("timezones/utcoffset.jl")
include("timezones/types.jl")
include("timezones/accessors.jl")
include("timezones/arithmetic.jl")
include("timezones/io.jl")
include("timezones/tzfile.jl")
include("timezones/adjusters.jl")
include("timezones/conversions.jl")
include("timezones/ranges.jl")
include("timezones/local.jl")
VERSION < v"0.5-" && include("timezones/local_mocking.jl")
include("timezones/discovery.jl")
include("TimeZones.jl")

# TODO: Doesn't seem appropriate to treat performance tests as test cases
# include("performance.jl")
