SUITE["transition_range"] = BenchmarkGroup()
SUITE["transition_range"]["local"] = BenchmarkGroup()
SUITE["transition_range"]["utc"] = BenchmarkGroup()

SUITE["transition_range"]["local"]["standard"] = begin
    @benchmarkable TimeZones.transition_range($(DateTime(2015,1,1)), $(tz"America/Winnipeg"), $Local)
end
SUITE["transition_range"]["local"]["non-existent"] = begin
    @benchmarkable TimeZones.transition_range($(DateTime(2015,3,8,2)), $(tz"America/Winnipeg"), $Local)
end
SUITE["transition_range"]["local"]["ambiguous"] = begin
    @benchmarkable TimeZones.transition_range($(DateTime(2015,11,1,1)), $(tz"America/Winnipeg"), $Local)
end
SUITE["transition_range"]["utc"] = begin
    @benchmarkable TimeZones.transition_range($(DateTime(2015,1,1)), $(tz"America/Winnipeg"), $UTC)
end


SUITE["interpret"] = BenchmarkGroup()
SUITE["interpret"]["local"] = BenchmarkGroup()
SUITE["interpret"]["utc"] = BenchmarkGroup()

SUITE["interpret"]["local"]["standard"] = begin
    @benchmarkable TimeZones.interpret($(DateTime(2015,1,1)), $(tz"America/Winnipeg"), $Local)
end
SUITE["interpret"]["local"]["non-existent"] = begin
    @benchmarkable TimeZones.interpret($(DateTime(2015,3,8,2)), $(tz"America/Winnipeg"), $Local)
end
SUITE["interpret"]["local"]["ambiguous"] = begin
    @benchmarkable TimeZones.interpret($(DateTime(2015,11,1,1)), $(tz"America/Winnipeg"), $Local)
end
SUITE["interpret"]["utc"] = begin
    @benchmarkable TimeZones.interpret($(DateTime(2015,1,1)), $(tz"America/Winnipeg"), $UTC)
end
