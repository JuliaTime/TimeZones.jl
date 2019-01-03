using PkgBenchmark
using TimeZones
import Dates: DateFormat
import TimeZones.TZData: parse_components

@benchgroup "parse" begin
    @bench "components" parse_components($("2010 Europe/Warsaw"), $(DateFormat("yyyy ZZZ")))

    # https://github.com/JuliaTime/TimeZones.jl/issues/25
    function parse_dates(n)
        df = DateFormat("yyyymmddHH:MM:SS ZZZ")
        arr = Array{ZonedDateTime}(n)
        for (i, s) in enumerate(Iterators.repeated("2016060701:02:03 America/Toronto", n))
            arr[i] = ZonedDateTime(s,df)
        end
        return arr
    end

    @bench "ZonedDateTime" parse_dates(1000)
end
