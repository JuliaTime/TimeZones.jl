using BenchmarkTools
using Dates: Day, Hour, DateFormat
using TimeZones
using TimeZones.TZData: parse_components

const SUITE = BenchmarkGroup()

include("tzdata.jl")
include("interpret.jl")
include("zoneddatetime.jl")
include("parse.jl")
