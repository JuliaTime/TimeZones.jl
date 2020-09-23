@testset "IndexableGenerator" begin
    @testset "basic" begin
        generator = TimeZones.IndexableGenerator(Char(i) for i in (1:26) .+ 96)

        @test length(generator) == 26
        @test size(generator) == (26,)
        @test axes(generator) == (Base.OneTo(26),)
        @test ndims(generator) == 1

        @test generator[26] == 'z'
        @test lastindex(generator) == 26

        @test collect(generator) == 'a':'z'
    end

    @testset "constructors" begin
        generator = TimeZones.IndexableGenerator(i -> Char(i), (1:26) .+ 96)
        @test collect(generator) == 'a':'z'

        generator = TimeZones.IndexableGenerator(Char, (1:26) .+ 96)
        @test collect(generator) == 'a':'z'
    end
end
