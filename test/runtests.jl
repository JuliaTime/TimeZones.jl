using TimeZones
using Base.Test

import TimeZones.Olsen: ZoneDict, RuleDict, tzparse, resolve

# For testing we'll reparse the tzdata every time to instead of using the serialized data.
# This should make the development/testing cycle simplier since you won't be forced to
# re-build the cache every time you make a change.
tzdata_dir = joinpath(dirname(@__FILE__), "..", "deps", "tzdata")

tzdata = Dict{String,Tuple{ZoneDict,RuleDict}}()
for name in ("australasia", "europe", "northamerica")
    tzdata[name] = tzparse(joinpath(tzdata_dir, name))
end

include("timezones/types.jl")
include("timezones/Olsen.jl")
include("timezones/arithmetic.jl")
