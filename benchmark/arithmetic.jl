SUITE["arithmetic"] = BenchmarkGroup()

SUITE["arithmetic"]["DatePeriod"] = begin
    zdt = ZonedDateTime(2000, 1, 2, tz"America/Winnipeg")
    @benchmarkable $zdt + $(Day(1))
end
SUITE["arithmetic"]["TimePeriod"] = begin
    zdt = ZonedDateTime(2000, 1, 2, tz"America/Winnipeg")
    @benchmarkable $zdt + $(Hour(1))
end
