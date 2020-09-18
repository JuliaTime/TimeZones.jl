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

SUITE["ZonedDateTime"]["time-period-range"] = begin
    @benchmarkable collect($(ZonedDateTime(2020, tz"America/Winnipeg"):Hour(1):ZonedDateTime(2021, tz"America/Winnipeg")))
end
SUITE["ZonedDateTime"]["date-period-range"] = begin
    @benchmarkable collect($(ZonedDateTime(2020, tz"America/Winnipeg"):Day(1):ZonedDateTime(2021, tz"America/Winnipeg")))
end
