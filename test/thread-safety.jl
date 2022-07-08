@testset "Thread safety" begin
    TimeZones._reset_tz_cache()

    @testset "Multithreaded TimeZone brute force test" begin
        function create_zdt(year, month, day, tz_name)
            ZonedDateTime(DateTime(year, month, day), TimeZone(tz_name))
        end
        function cycle_zdts()
            return [
                try
                    create_zdt(year, month, day, tz_name)
                catch e
                    # Ignore ZonedDateTimes that aren't valid
                    e isa Union{ArgumentError,AmbiguousTimeError,NonExistentTimeError} || rethrow()
                    nothing
                end
                for year in 2000:2020
                for month in 1:5
                for day in 10:15
                for tz_name in timezone_names()
            ]
        end

        outputs = Channel(Inf)
        @sync begin
            for _ in 1:15
                Threads.@spawn begin
                    put!(outputs, cycle_zdts())
                end
            end
        end
        close(outputs)

        tzs = collect(outputs)

        # Test that every Task produced the same result
        allsame(x) = all(y -> y == first(x), x)
        @test allsame(tzs)
    end

    @testset "Interleaved compile() and TimeZone construction" begin
        @sync for i in 1:20
            if (i % 5 == 0)
                TimeZones.TZData.compile()
            end
            Threads.@spawn begin
                TimeZone("US/Eastern", TimeZones.Class(:LEGACY))
            end
        end
    end
end
