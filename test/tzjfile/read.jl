using TimeZones: TZJFile

const TZJFILE_DIR = joinpath(@__DIR__, "data")

@testset "read_signature" begin
    @test TZJFile.read_signature(IOBuffer(b"TZjf")) == b"TZjf"
    @test_throws ArgumentError TZJFile.read_signature(IOBuffer(b"TZya"))
end

@testset "read_version" begin
    @test TZJFile.read_version(IOBuffer([hton(0x01)])) == 1
    @test TZJFile.read_version(IOBuffer([hton(0xff)])) == Int(0xff)
end

@testset "read" begin
    # Tests the basic `FixedTimeZone` code path
    @testset "UTC" begin
        utc, class = FixedTimeZone("UTC", 0), Class(:FIXED)
        tzj_utc, tzj_class = open(joinpath(TZJFILE_DIR, "UTC"), "r") do fp
            TZJFile.read(fp)("UTC")
        end
        @test tzj_utc == utc
        @test tzj_class == class
    end

    # Tests the basic `VariableTimeZone` code path
    @testset "Europe/Warsaw" begin
        warsaw, class = compile("Europe/Warsaw", tzdata["europe"])
        tzj_warsaw, tzj_class = open(joinpath(TZJFILE_DIR, "Europe", "Warsaw"), "r") do fp
            TZJFile.read(fp)("Europe/Warsaw")
        end
        @test tzj_warsaw == warsaw
        @test tzj_class == class
    end

    # Ensure the tzjfile format can handle Europe/Moscow as it is challenging tzfile
    @testset "Europe/Moscow" begin
        moscow, class = compile("Europe/Moscow", tzdata["europe"])
        tzj_moscow, tzj_class = open(joinpath(TZJFILE_DIR, "Europe", "Moscow"), "r") do fp
            TZJFile.read(fp)("Europe/Moscow")
        end
        @test tzj_moscow == moscow
        @test tzj_class == class
    end

    # As we use dispatch for chosing how to parse a version of a tzjfile attempting to read
    # a newer version that TimeZones.jl does not understand results in a `MethodError`
    @testset "Future_Version" begin
        @test_throws MethodError open(joinpath(TZJFILE_DIR, "Future_Version"), "r") do fp
            TZJFile.read(fp)("Future_Version")
        end
    end
end
