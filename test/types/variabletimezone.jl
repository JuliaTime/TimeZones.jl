@testset "VariableTimeZone" begin
    @testset "equality" begin
        warsaw = compile("Europe/Warsaw", tzdata["europe"])
        another_warsaw = compile("Europe/Warsaw", tzdata["europe"])

        @test warsaw == warsaw
        @test warsaw === warsaw
        @test warsaw == another_warsaw
        @test warsaw !== another_warsaw
        @test isequal(warsaw, another_warsaw)
        @test hash(warsaw) == hash(another_warsaw)
    end

    @testset "links" begin
        # "Arctic/Longyearbyen" is a link to "Europe/Oslo"
        oslo = compile("Europe/Oslo", tzdata["europe"])
        longyearbyen = compile("Arctic/Longyearbyen", tzdata["europe"])

        @test oslo.name != longyearbyen.name
        @test oslo.transitions == longyearbyen.transitions
        @test oslo.cutoff == longyearbyen.cutoff

        @test oslo != longyearbyen
        @test oslo !== longyearbyen
        @test !isequal(oslo, longyearbyen)
        @test hash(oslo) != hash(longyearbyen)
    end

    @testset "cutoff differs" begin
        a = compile("Europe/Warsaw", tzdata["europe"])
        b = VariableTimeZone(a.name, a.transitions, nothing)

        @test a.name == b.name
        @test a.transitions == b.transitions
        @test a.cutoff != b.cutoff

        @test a == b
        @test a !== b
        @test !isequal(a, b)
        @test hash(a) != hash(b)
    end
end
