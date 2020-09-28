SUITE["ZonedDateTime"] = BenchmarkGroup()
SUITE["ZonedDateTime"]["local"] = BenchmarkGroup()
SUITE["ZonedDateTime"]["utc"] = BenchmarkGroup()

SUITE["ZonedDateTime"]["local"]["standard"] = begin
    @benchmarkable ZonedDateTime($(DateTime(2015,1,1)), $(tz"America/Winnipeg"))
end
SUITE["ZonedDateTime"]["local"]["ambiguous"] = begin
    @benchmarkable ZonedDateTime($(DateTime(2015,11,1,1)), $(tz"America/Winnipeg"), 2)
end
SUITE["ZonedDateTime"]["utc"] = begin
    @benchmarkable ZonedDateTime($(DateTime(2015,1,1)), $(tz"America/Winnipeg"), from_utc=true)
end


SUITE["ZonedDateTime"]["range"] = BenchmarkGroup()

SUITE["ZonedDateTime"]["range"]["VariableTimeZone/TimePeriod"] = begin
    @benchmarkable collect($(gen_range(Hour(100), tz"America/Winnipeg")))
end
SUITE["ZonedDateTime"]["range"]["VariableTimeZone/DatePeriod"] = begin
    @benchmarkable collect($(gen_range(Day(100), tz"America/Winnipeg")))
end
SUITE["ZonedDateTime"]["range"]["FixedTimeZone/TimePeriod"] = begin
    @benchmarkable collect($(gen_range(Hour(100), tz"UTC")))
end
SUITE["ZonedDateTime"]["range"]["FixedTimeZone/DatePeriod"] = begin
    @benchmarkable collect($(gen_range(Day(100), tz"UTC")))
end

# https://github.com/JuliaTime/TimeZones.jl/pull/287#issuecomment-687358202
SUITE["ZonedDateTime"]["fill"] = begin
    f(zdt) = fill(zdt, 100)[end]
    @benchmarkable f($(ZonedDateTime(2000, 1, 2, tz"America/Winnipeg")))
end
