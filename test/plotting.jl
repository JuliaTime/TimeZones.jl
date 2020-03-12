@testset "ZonedDateTime plot recipe" begin
    start_zdt = ZonedDateTime(2017,1,1,0,0,0, tz"EST")
    end_zdt = ZonedDateTime(2017,1,1,10,30,0, tz"EST")
    zoned_dates = start_zdt:Hour(1):end_zdt

    result = scatter(zoned_dates, 1:11)

    date_val(zdt) = Dates.value(DateTime(zdt, UTC))
    x_axis = result.subplots[1][:xaxis]
    @test x_axis[:extrema].emin ≈ date_val(start_zdt) rtol=0.000_000_1
    @test x_axis[:extrema].emax ≈ date_val(end_zdt) rtol=0.000_000_1
end
