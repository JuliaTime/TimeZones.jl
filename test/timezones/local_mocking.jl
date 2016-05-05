import TimeZones: TimeZone, localzone
using Mocking
import Compat: readstring

# For mocking make sure we are actually changing the timezone
name = string(localzone()) == "Europe/Warsaw" ? "Pacific/Apia" : "Europe/Warsaw"

tzfile_path = joinpath(TZFILE_DIR, split(name, '/')...)
@assert isfile(tzfile_path) "Tests require a local tzfile present"
win_name = name == "Europe/Warsaw" ? "Central European Standard Time" : "Samoa Standard Time"
timezone = TimeZone(name)

if OS_NAME == :Darwin
    # Determine timezone via systemsetup.
    mock_readstring = (cmd::Base.AbstractCmd) -> "Time Zone:  $name\n"
    patches = [
        Patch(readstring, mock_readstring)
    ]
    mend(patches) do
        @test localzone() == timezone
    end

    # Determine timezone from /etc/localtime.
    mock_readstring = (cmd::Base.AbstractCmd) -> ""
    mock_readlink = (filename::AbstractString) -> "/usr/share/zoneinfo/$name"
    patches = [
        Patch(readstring, mock_readstring)
        Patch(Base.readlink, mock_readlink)
    ]
    mend(patches) do
        @test localzone() == timezone
    end

elseif OS_NAME == :Windows
    mock_readstring = (cmd::Base.AbstractCmd) -> "$win_name\r\n"
    patches = [
        Patch(readstring, mock_readstring)
    ]
    mend(patches) do
        @test localzone() == timezone
    end

    # Dateline Standard Time -> Etc/GMT+12 -> UTC-12:00

elseif OS_NAME == :Linux
    # Test TZ environmental variable
    withenv("TZ" => ":$name") do
        @test localzone() == timezone
    end

    withenv("TZ" => nothing) do
        # Determine timezone from /etc/timezone
        mock_isfile = (f::AbstractString) -> f == "/etc/timezone" || Original.isfile(f)
        mock_open = (fn::Function, f::AbstractString) -> f == "/etc/timezone" ? fn(IOBuffer("$name #Works with comments\n")) : Original.open(fn, f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.open, mock_open)
        ]
        mend(patches) do
            @test localzone() == timezone
        end

        # Determine timezone from /etc/conf.d/clock
        mock_isfile = (f::AbstractString) -> !(f in ("/etc/timezone", "/etc/sysconfig/clock")) && (f == "/etc/conf.d/clock" || Original.isfile(f))
        mock_open = (fn::Function, f::AbstractString) -> f == "/etc/conf.d/clock" ? fn(IOBuffer("\n\nTIMEZONE=\"$name\"")) : Original.open(fn, f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.open, mock_open)
        ]
        mend(patches) do
            @test localzone() == timezone
        end

        # Determine timezone from symlink /etc/localtime
        mock_isfile = (f::AbstractString) -> !(f in ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock")) && Original.isfile(f)
        mock_islink = (f::AbstractString) -> f == "/etc/localtime" || Original.islink(f)
        mock_readlink = (f::AbstractString) -> f == "/etc/localtime" ? "/usr/share/zoneinfo/$name" : Original.readlink(f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.islink, mock_islink)
            Patch(Base.readlink, mock_readlink)
        ]
        mend(patches) do
            @test localzone() == timezone
        end

        # Determine timezone from contents of /etc/localtime
        tz_from_file = open(tzfile_path) do f
            TimeZones.read_tzfile(f, "local")
        end

        mock_isfile = (f::AbstractString) -> !(f in ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock")) && (f == "/etc/localtime" || Original.isfile(f))
        mock_islink = (f::AbstractString) -> f != "/etc/localtime" && Original.islink(f)
        mock_open = (fn::Function, f::AbstractString) -> f == "/etc/localtime" ? fn(open(tzfile_path)) : Original.open(fn, f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.islink, mock_islink)
            Patch(Base.open, mock_open)
        ]

        mend(patches) do
            @test localzone() == tz_from_file
        end

        # Unable to determine timezone
        mock_isfile = (f::AbstractString) -> !(f in ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock", "/etc/localtime", "/usr/local/etc/localtime")) && Original.isfile(f)
        mock_islink = (f::AbstractString) -> f != "/etc/localtime" && Original.islink(f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.islink, mock_islink)
        ]
        mend(patches) do
            @test_throws ErrorException localzone()
        end
    end
end
