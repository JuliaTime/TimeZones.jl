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
end
