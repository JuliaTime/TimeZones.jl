using TimeZones: Class, Transition

@testset "Class" begin
    @testset "construct" begin
        @test Class(:NONE) == Class(0x00)
        @test Class(:FIXED) == Class(0x01)
        @test Class(:STANDARD) == Class(0x02)
        @test Class(:LEGACY) == Class(0x04)

        @test Class(:DEFAULT) == Class(0x01 | 0x02)
        @test Class(:ALL) == Class(0x07)
    end

    @testset "getproperty field fallback" begin
        @test Class isa DataType
        @test sprint(show, Class) == "Class"
    end

    @testset "classify name/regions" begin
        @test Class("Foobar", []) == Class(:NONE)
        @test Class("UTC+1", []) == Class(:FIXED)
        @test Class("Europe/Warsaw", ["europe"]) == Class(:STANDARD)
        @test Class("US/Pacific", ["backward"]) == Class(:LEGACY)
        @test Class("Etc/GMT-14", ["etcetera"]) == Class(:LEGACY)
        @test Class("UTC", ["utc", "backward"]) == Class(:FIXED) | Class(:STANDARD) | Class(:LEGACY)
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

    @testset "repr" begin
        @test repr(Class(:NONE)) == "Class(:NONE)"
        @test repr(Class(:FIXED)) == "Class(:FIXED)"
        @test repr(Class(:STANDARD)) == "Class(:STANDARD)"
        @test repr(Class(:LEGACY)) == "Class(:LEGACY)"

        @test repr(Class(:DEFAULT)) == "Class(:FIXED) | Class(:STANDARD)"
        @test repr(Class(:ALL)) == "Class(:FIXED) | Class(:STANDARD) | Class(:LEGACY)"

        @test repr(Class(0x08)) == "Class(0x08)"
        @test repr(Class(0x09)) == "Class(:FIXED) | Class(0x08)"
    end
end
