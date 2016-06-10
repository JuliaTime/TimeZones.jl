using TimeZones
using Base.Test

let parse1, parse2, iterations = 1000
    function parse1(n)
        df = Dates.DateFormat("yyyymmddHH:MM:SS")
        ltz = TimeZone("America/Toronto")
        arr = Array{ZonedDateTime}(n)
        for (i, s) in enumerate(repeated("2016060701:02:03", n))
            arr[i] = ZonedDateTime(DateTime(s,df),ltz)
        end
        return arr
    end

    function parse2(n)
        df = Dates.DateFormat("yyyymmddHH:MM:SS ZZZ")
        arr = Array{ZonedDateTime}(n)
        for (i, s) in enumerate(repeated("2016060701:02:03 America/Toronto", n))
            arr[i] = ZonedDateTime(s,df)
        end
        return arr
    end

    # Pre-compile and make sure the results are the same
    @test parse1(iterations) == parse2(iterations)

    time1 = @elapsed parse1(iterations)
    time2 = @elapsed parse2(iterations)
    @test abs(time1 - time2) < 0.1
end
