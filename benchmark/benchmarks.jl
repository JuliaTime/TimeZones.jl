using BenchmarkTools
using Dates: Day, Hour, DateFormat, @dateformat_str
using TimeZones
using TimeZones.TZData: parse_components
using Test: GenericString

const SUITE = BenchmarkGroup()

include("tzdata.jl")
include("interpret.jl")
include("zoneddatetime.jl")
include("arithmetic.jl")
include("parse.jl")
