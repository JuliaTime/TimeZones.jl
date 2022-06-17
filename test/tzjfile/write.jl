using TimeZones: TZJFile

@testset "write_signature" begin
    @test bprint(TZJFile.write_signature) == b"TZjf"
end

@testset "write_version" begin
    @test bprint(io -> TZJFile.write_version(io, version=1)) == [ntoh(UInt8(1))]
    @test bprint(io -> TZJFile.write_version(io, version=255)) == [ntoh(UInt8(255))]
    @test_throws InexactError bprint(io -> TZJFile.write_version(io, version=256))
end

@testset "write" begin
    # Tests the basic `FixedTimeZone` code path
    @testset "UTC" begin
        utc, class = FixedTimeZone("UTC", 0), Class(:FIXED)
        io = IOBuffer()
        TZJFile.write(io, utc; class)
        tzj_utc, tzj_class = TZJFile.read(seekstart(io))("UTC")

        @test tzj_utc == utc
        @test tzj_class == class
    end

    # Tests the basic `VariableTimeZone` code path
    @testset "Europe/Warsaw" begin
        warsaw, class = compile("Europe/Warsaw", tzdata["europe"])
        io = IOBuffer()
        TZJFile.write(io, warsaw; class)
        tzj_warsaw, tzj_class = TZJFile.read(seekstart(io))("Europe/Warsaw")

        @test tzj_warsaw == warsaw
        @test tzj_class == class
    end

    @testset "Europe/Moscow" begin
        moscow, class = compile("Europe/Moscow", tzdata["europe"])
        io = IOBuffer()
        TZJFile.write(io, moscow; class)
        tzj_moscow, tzj_class = TZJFile.read(seekstart(io))("Europe/Moscow")

        @test tzj_moscow == moscow
        @test tzj_class == class
    end
end
