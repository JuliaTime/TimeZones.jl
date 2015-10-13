using TimeZones
using Base.Test

import TimeZones: TZDATA_DIR
import TimeZones.Olson: ZoneDict, RuleDict, tzparse, resolve

const TEST_DIR = normpath(dirname(@__FILE__))
const TZFILE_DIR = joinpath(TEST_DIR, "tzfile")

# For testing we'll reparse the tzdata every time to instead of using the serialized data.
# This should make the development/testing cycle simplier since you won't be forced to
# re-build the cache every time you make a change.
#
# Note: resolving only the timezones we want is much faster than running compile which
# recompiles all the timezones.
tzdata = Dict{AbstractString,Tuple{ZoneDict,RuleDict}}()
for name in ("australasia", "europe", "northamerica")
    tzdata[name] = tzparse(joinpath(TZDATA_DIR, name))
end

include("timezones/time.jl")
include("timezones/types.jl")
include("timezones/Olson.jl")
include("timezones/accessors.jl")
include("timezones/arithmetic.jl")
include("timezones/io.jl")
include("timezones/tzfile.jl")
include("timezones/adjusters.jl")
include("timezones/conversions.jl")
include("timezones/local.jl")
include("timezone_names.jl")
