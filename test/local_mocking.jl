using Base: AbstractCmd
using Mocking: @patch, apply
using TimeZones: TimeZone, localzone

# For mocking make sure we are actually changing the time zone
name = string(localzone()) == "Europe/Warsaw" ? "Pacific/Apia" : "Europe/Warsaw"

tzfile_path = joinpath(TZFILE_DIR, split(name, '/')...)
@assert isfile(tzfile_path) "Tests require a local tzfile present"
win_name = name == "Europe/Warsaw" ? "Central European Standard Time" : "Samoa Standard Time"
tz = TimeZone(name)

if Sys.iswindows()
    patch = @patch read(cmd::AbstractCmd, ::Type{String}) = win_name
    apply(patch) do
        @test localzone() == tz
    end

    # Dateline Standard Time -> Etc/GMT+12 -> UTC-12:00

elseif Sys.isunix()
    withenv("TZ" => nothing) do
        if Sys.islinux()
            # Determine time zone from /etc/timezone
            patches = [
                @patch isfile(f::AbstractString) = f == "/etc/timezone"
                @patch open(fn::Function, f::AbstractString) = fn(IOBuffer("$name #Works with comments\n"))
            ]
            apply(patches) do
                @test localzone() == tz
            end

            # Determine time zone from /etc/conf.d/clock
            patches = [
                @patch isfile(f::AbstractString) = f == "/etc/conf.d/clock"
                @patch open(fn::Function, f::AbstractString) = fn(IOBuffer("\n\nTIMEZONE=\"$name\""))
            ]
            apply(patches) do
                @test localzone() == tz
            end
        end

        # Determine time zone from symlink /etc/localtime
        patches = [
            @patch isfile(f::AbstractString) = false
            @patch islink(f::AbstractString) = f == "/etc/localtime"
            @patch readlink(f::AbstractString) = "/usr/share/zoneinfo/$name"
        ]
        apply(patches) do
            @test localzone() == tz
        end

        # Determine time zone from contents of /etc/localtime
        tz_from_file = open(tzfile_path) do f
            TZFile.read(f)("local")
        end

        patches = [
            @patch isfile(f::AbstractString) = f == "/etc/localtime"
            @patch islink(f::AbstractString) = false
            @patch open(fn::Function, f::AbstractString) = fn(open(tzfile_path))
        ]
        apply(patches) do
            @test localzone() == tz_from_file
        end

        # Unable to determine time zone
        patches = [
            @patch isfile(f::AbstractString) = false
            @patch islink(f::AbstractString) = false
        ]
        apply(patches) do
            @test_throws ErrorException localzone()
        end
    end
end

# Generates a cross-platform patched environment to run `localzone()`
function with_localzone(func::Function, name::AbstractString)
    @static if Sys.isapple()
        patches = [
            @patch islink(f::AbstractString) = f == "/etc/localtime"
            @patch readlink(::AbstractString) = "/usr/share/zoneinfo/$name"
        ]
    elseif Sys.iswindows()
        patches = [
            @patch read(cmd::AbstractCmd, ::Type{String}) = name
        ]
    elseif Sys.islinux()
        patches = [
            @patch isfile(f::AbstractString) = f == "/etc/timezone"
            @patch open(fn::Function, f::AbstractString) = fn(IOBuffer("$name\n"))
        ]
    else
        error("Unhandled OS")
    end

    withenv("TZ" => nothing) do
        apply(patches) do
            func()
        end
    end
end

# https://github.com/JuliaTime/TimeZones.jl/issues/154
@testset "legacy time zones" begin
    # "US/Pacific" is deprecated in favor of "America/Los_Angeles"
    @test istimezone("US/Pacific", Class(:LEGACY))
    name = Sys.isunix() ? "US/Pacific" : "Pacific Standard Time"
    with_localzone(name) do
        @test localzone().transitions == tz"America/Los_Angeles".transitions
    end

    # "America/Montreal" is deprecated in favor of "America/Toronto"
    @test istimezone("America/Montreal", Class(:LEGACY))
    if Sys.isunix()
        with_localzone("America/Montreal") do
            @test localzone().transitions == tz"America/Toronto".transitions
        end
    end

    # "America/Indianapolis" is deprecated in favor of "America/Indiana/Indianapolis"
    # Note: On Windows "US Eastern Standard Time" translates to "America/Indianapolis"
    @test istimezone("America/Indianapolis", Class(:LEGACY))
    name = Sys.isunix() ? "America/Indianapolis" : "US Eastern Standard Time"
    with_localzone(name) do
        @test localzone().transitions == tz"America/Indiana/Indianapolis".transitions
    end
end
