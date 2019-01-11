using TimeZones: Class, Transition

@testset "Class" begin
    @testset "construct" begin
        @test Class.NONE == Class(0x00)
        @test Class.FIXED == Class(0x01)
        @test Class.STANDARD == Class(0x02)
        @test Class.LEGACY == Class(0x04)

        @test Class.DEFAULT == Class(0x01 | 0x02)
        @test Class.ALL == Class(0x07)
    end

    @testset "getproperty field fallback" begin
        @test Class isa DataType
        @test sprint(show, Class) == "Class"
    end

    @testset "classify" begin
        @test TimeZones.classify("Foobar", []) == Class.NONE
        @test TimeZones.classify("UTC+1", []) == Class.FIXED
        @test TimeZones.classify("Europe/Warsaw", ["europe"]) == Class.STANDARD
        @test TimeZones.classify("US/Pacific", ["backward"]) == Class.LEGACY
        @test TimeZones.classify("Etc/GMT-14", ["etcetera"]) == Class.LEGACY
        @test TimeZones.classify("UTC", ["utc", "backward"]) == Class.FIXED | Class.STANDARD | Class.LEGACY
    end

    @testset "bitwise-or" begin
        @test Class(0x00) | Class(0x00) == Class(0x00)
        @test Class(0x00) | Class(0x01) == Class(0x01)
        @test Class(0x01) | Class(0x00) == Class(0x01)
        @test Class(0x01) | Class(0x01) == Class(0x01)
    end

    @testset "bitwise-and" begin
        @test Class(0x00) & Class(0x00) == Class(0x00)
        @test Class(0x00) & Class(0x01) == Class(0x00)
        @test Class(0x01) & Class(0x00) == Class(0x00)
        @test Class(0x01) & Class(0x01) == Class(0x01)
    end

    @testset "labels" begin
        @test TimeZones.labels(Class.NONE) == ["NONE"]
        @test TimeZones.labels(Class.FIXED) == ["FIXED"]
        @test TimeZones.labels(Class.STANDARD) == ["STANDARD"]
        @test TimeZones.labels(Class.LEGACY) == ["LEGACY"]

        @test TimeZones.labels(Class.DEFAULT) == ["FIXED", "STANDARD"]
        @test TimeZones.labels(Class.ALL) == ["FIXED", "STANDARD", "LEGACY"]

        @test TimeZones.labels(Class(0x08)) == String[]
    end

    @testset "string" begin
        @test string(Class.DEFAULT) == "FIXED | STANDARD"
    end

    @testset "repr" begin
        @test repr(Class.DEFAULT) == "Class.FIXED | Class.STANDARD"
    end
end
