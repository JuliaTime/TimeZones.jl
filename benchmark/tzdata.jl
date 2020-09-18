SUITE["tz_data"] = BenchmarkGroup()

SUITE["tz_data"]["parse_components"] = begin
    @benchmarkable parse_components($("2010 Europe/Warsaw"), $(DateFormat("yyyy ZZZ")))
end
