using BenchmarkTools
using Dates: Period, Day, Hour, DateFormat, @dateformat_str
using TimeZones
using TimeZones.TZData: parse_components, build
using Test: GenericString

const SUITE = BenchmarkGroup()

function gen_range(num_units::Period, tz::TimeZone)
    zdt = ZonedDateTime(2000, tz)
    return StepRange(zdt, oneunit(num_units), zdt + num_units)
end

# Ensure that when comparing benchmarks 
# That the compiled TZData is compatible with this version
build("2016j") # version consistent with tests

include("tzdata.jl")
include("interpret.jl")
include("zoneddatetime.jl")
include("arithmetic.jl")
include("parse.jl")
