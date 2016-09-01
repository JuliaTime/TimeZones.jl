using TimeZones
using BenchmarkTools

suite = BenchmarkGroup()
suite["parse"] = BenchmarkGroup()

# Parsing a ZonedDateTime using the Z slot
function multiple(n)
    df = Dates.DateFormat("yyyymmddHH:MM:SS ZZZ")
    arr = Array{ZonedDateTime}(n)
    for (i, s) in enumerate(repeated("2016060701:02:03 America/Toronto", n))
        arr[i] = ZonedDateTime(s,df)
    end
    return arr
end
suite["parse"]["multiple"] = @benchmarkable multiple(1000)

suite
