SUITE["parse"] = BenchmarkGroup()

# https://github.com/JuliaTime/TimeZones.jl/issues/25
function parse_dates(n)
    df = DateFormat("yyyymmddHH:MM:SS ZZZ")
    arr = Vector{ZonedDateTime}(undef, n)
    for (i, s) in enumerate(Iterators.repeated("2016060701:02:03 America/Toronto", n))
        arr[i] = ZonedDateTime(s,df)
    end
    return arr
end

SUITE["parse"]["issue#25"] = @benchmarkable parse_dates(1000)
