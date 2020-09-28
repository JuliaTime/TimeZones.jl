using BenchmarkTools
using Dates: Period, Day, Hour, DateFormat, @dateformat_str
using TimeZones
using TimeZones.TZData: parse_components
using Test: GenericString

const SUITE = BenchmarkGroup()

function gen_range(num_units::Period, tz::TimeZone)
    zdt = ZonedDateTime(2000, tz)
    return StepRange(zdt, oneunit(num_units), zdt + num_units)
end

include("tzdata.jl")
include("interpret.jl")
include("zoneddatetime.jl")
include("arithmetic.jl")
include("parse.jl")
