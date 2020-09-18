using BenchmarkTools
using Dates: DateFormat
using TimeZones
using TimeZones.TZData: parse_components

const SUITE = BenchmarkGroup()

include("parse.jl")
