SUITE["arithmetic"] = BenchmarkGroup()

SUITE["arithmetic"]["DatePeriod"] = begin
    zdt = ZonedDateTime(2000, 1, 2, tz"America/Winnipeg")
    @benchmarkable $zdt + $(Day(1))
end
SUITE["arithmetic"]["TimePeriod"] = begin
    zdt = ZonedDateTime(2000, 1, 2, tz"America/Winnipeg")
    @benchmarkable $zdt + $(Hour(1))
end


SUITE["arithmetic"]["broadcast"] = BenchmarkGroup()

SUITE["arithmetic"]["broadcast"]["VariableTimeZone/TimePeriod"] = begin
    @benchmarkable $(gen_range(Hour(100), tz"America/Winnipeg")) .+ Hour(1)
end
SUITE["arithmetic"]["broadcast"]["VariableTimeZone/DatePeriod"] = begin
    @benchmarkable $(gen_range(Day(100), tz"America/Winnipeg")) .+ Day(1)
end
SUITE["arithmetic"]["broadcast"]["FixedTimeZone/TimePeriod"] = begin
    @benchmarkable $(gen_range(Hour(100), tz"UTC")) .+ Hour(1)
end
SUITE["arithmetic"]["broadcast"]["FixedTimeZone/DatePeriod"] = begin
    @benchmarkable $(gen_range(Day(100), tz"UTC")) .+ Day(1)
end
