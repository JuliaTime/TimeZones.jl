@testset "ZonedDateTime plot recipe" begin
    # Note: in these tests we use `RecipesBase.apply_recipe` rather than `plot` as it
    # lets use avoid a Plots.jl dependency and issues with running that during tests.
    # `RecipesBase.apply_recipe` is not a documented API, but is fairly usable.
    # Comments above each use show the matching `plot` function command
    tz = FixedTimeZone("EST", -18000)
    start_zdt = ZonedDateTime(2017,1,1,0,0,0, tz)
    end_zdt = ZonedDateTime(2017,1,1,10,30,0, tz)
    zoned_dates = start_zdt:Hour(1):end_zdt

    # what the point should be after recipe is applied
    expected_dates = DateTime.(zoned_dates)

    @testset "No label (should now say the Timezone)" begin
        # The below use of `apply_recipe` is equivelent to:
        # plot(zoned_dates, 1:11)
        result, = RecipesBase.apply_recipe(Dict{Symbol, Any}(), zoned_dates, 1:11)
        xs, ys = result.args
        @test xs == expected_dates
        @test ys == 1:11
        @test result.plotattributes[:xguide] == "Time zone: EST"
    end

    @testset "label (should append to it)" begin
        # The below use of `apply_recipe` is equivelent to:
        # plot(zoned_dates, 1:11; xguide="X-Axis")
        result, = RecipesBase.apply_recipe(Dict{Symbol, Any}(:xguide=>"X-Axis"), zoned_dates, 1:11)
        xs, ys = result.args
        @test xs == expected_dates
        @test ys == 1:11
        @test result.plotattributes[:xguide] == "X-Axis (EST)"
    end

    @testset "No items" begin
        empty_xs = ZonedDateTime[]
        empty_ys = 0:-1
        result, = RecipesBase.apply_recipe(
           Dict{Symbol, Any}(:xguide=>"X-Axis"), empty_xs, empty_ys
        )
        xs, ys = result.args
        @test isempty(xs)  # not nesc same type
        @test ys == empty_ys

        @test result.plotattributes[:xguide] == "X-Axis"  # no change to axis
    end
end
