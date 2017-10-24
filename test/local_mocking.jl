import TimeZones: TimeZone, localzone
import Mocking: @patch, apply
import Base: AbstractCmd
import Compat: Sys, read

# For mocking make sure we are actually changing the time zone
name = string(localzone()) == "Europe/Warsaw" ? "Pacific/Apia" : "Europe/Warsaw"

tzfile_path = joinpath(TZFILE_DIR, split(name, '/')...)
@assert isfile(tzfile_path) "Tests require a local tzfile present"
win_name = name == "Europe/Warsaw" ? "Central European Standard Time" : "Samoa Standard Time"
timezone = TimeZone(name)

if Sys.isapple()
    # Determine time zone via systemsetup.
    patch = @patch read(cmd::AbstractCmd, ::Type{String}) = "Time Zone:  " * name * "\n"
    apply(patch) do
        @test localzone() == timezone
    end

    # Determine time zone from /etc/localtime.
    patches = [
        @patch read(cmd::AbstractCmd, ::Type{String}) = ""
        @patch readlink(filename::AbstractString) = "/usr/share/zoneinfo/$name"
    ]
    apply(patches) do
        @test localzone() == timezone
    end

elseif Sys.iswindows()
    patch = @patch read(cmd::AbstractCmd, ::Type{String}) = "$win_name\r\n"
    apply(patch) do
        @test localzone() == timezone
    end

    # Dateline Standard Time -> Etc/GMT+12 -> UTC-12:00

elseif Sys.islinux()
    # Test TZ environmental variable
    withenv("TZ" => ":$name") do
        @test localzone() == timezone
    end

    withenv("TZ" => nothing) do
        # Determine time zone from /etc/timezone
        patches = [
            @patch isfile(f::AbstractString) = f == "/etc/timezone"
            @patch open(fn::Function, f::AbstractString) = fn(IOBuffer("$name #Works with comments\n"))
        ]
        apply(patches) do
            @test localzone() == timezone
        end

        # Determine time zone from /etc/conf.d/clock
        patches = [
            @patch isfile(f::AbstractString) = f == "/etc/conf.d/clock"
            @patch open(fn::Function, f::AbstractString) = fn(IOBuffer("\n\nTIMEZONE=\"$name\""))
        ]
        apply(patches) do
            @test localzone() == timezone
        end

        # Determine time zone from symlink /etc/localtime
        patches = [
            @patch isfile(f::AbstractString) = false
            @patch islink(f::AbstractString) = f == "/etc/localtime"
            @patch readlink(f::AbstractString) = "/usr/share/zoneinfo/$name"
        ]
        apply(patches) do
            @test localzone() == timezone
        end

        # Determine time zone from contents of /etc/localtime
        tz_from_file = open(tzfile_path) do f
            TimeZones.read_tzfile(f, "local")
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
