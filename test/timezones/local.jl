import TimeZones: TimeZone, localzone
using Mocking

# Make sure that the current systems local timezone is supported.
local_tz = localzone()
@test isa(local_tz, TimeZone)


@linux_only begin
    # Bad TZ environmental variables
    withenv("TZ" => "") do
        @test_throws ErrorException localzone()
    end
    withenv("TZ" => "Europe/Warsaw") do
        @test_throws ErrorException localzone()
    end

    # Absolute filespec
    warsaw_path = joinpath(TZFILE_DIR, "Europe", "Warsaw")
    warsaw_from_file = open(warsaw_path) do f
        TimeZones.read_tzfile(f, "local")
    end
    withenv("TZ" => ":" * abspath(warsaw_path)) do
        @test localzone() == warsaw_from_file
    end

    # Relative filespec
    warsaw = TimeZone("Europe/Warsaw")
    withenv("TZ" => ":Europe/Warsaw") do
        @test localzone() == warsaw
    end

    # Set TZDIR and use timezone unrecognized by TimeZone
    @test_throws ErrorException TimeZone("Etc/UTC")
    utc = open(joinpath(TZFILE_DIR, "Etc", "UTC")) do f
        TimeZones.read_tzfile(f, "Etc/UTC")
    end
    withenv("TZ" => ":Etc/UTC", "TZDIR" => TZFILE_DIR) do
        @test localzone() == utc
    end

    # Use system installed files
    @test_throws ErrorException TimeZone("Etc/GMT-9")
    gmt_minus_9 = FixedTimeZone("Etc/GMT-9", 9 * 3600)
    withenv("TZ" => ":Etc/GMT-9") do
        @test localzone() == gmt_minus_9
    end

    # Unable to locate timezone on system
    withenv("TZ" => ":") do
        @test_throws SystemError localzone()
    end
    withenv("TZ" => ":Etc/Foo") do
        @test_throws SystemError localzone()
    end
end

# For mocking make sure we are actually changing the timezone
name = string(local_tz) == "Europe/Warsaw" ? "Pacific/Apia" : "Europe/Warsaw"

tzfile_path = joinpath(TZFILE_DIR, split(name, '/')...)
@assert isfile(tzfile_path) "Tests require a local tzfile present"
win_name = name == "Europe/Warsaw" ? "Central European Standard Time" : "Samoa Standard Time"
timezone = TimeZone(name)

if OS_NAME == :Darwin
    # Determine timezone via systemsetup.
    mock_readall = (cmd::Base.AbstractCmd) -> "Time Zone:  $name\n"
    patches = [
        Patch(Base.readall, mock_readall)
    ]
    mend(patches) do
        @test localzone() == timezone
    end

    # Determine timezone from /etc/localtime.
    mock_readall = (cmd::Base.AbstractCmd) -> ""
    mock_readlink = (filename::AbstractString) -> "/usr/share/zoneinfo/$name"
    patches = [
        Patch(Base.readall, mock_readall)
        Patch(Base.readlink, mock_readlink)
    ]
    mend(patches) do
        @test localzone() == timezone
    end

elseif OS_NAME == :Windows
    mock_readall = (cmd::Base.AbstractCmd) -> "$win_name\r\n"
    patches = [
        Patch(Base.readall, mock_readall)
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
        ignore = ("/etc/timezone", "/etc/sysconfig/clock")
        mock_isfile = (f::AbstractString) -> !(f in ignore) && (f == "/etc/conf.d/clock" || Original.isfile(f))
        mock_open = (fn::Function, f::AbstractString) -> f == "/etc/conf.d/clock" ? fn(IOBuffer("\n\nTIMEZONE=\"$name\"")) : Original.open(fn, f)
        patches = [
            Patch(Base.isfile, mock_isfile)
            Patch(Base.open, mock_open)
        ]
        mend(patches) do
            @test localzone() == timezone
        end

        # Determine timezone from symlink /etc/localtime
        ignore = ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock")
        mock_isfile = (f::AbstractString) -> !(f in ignore) && Original.isfile(f)
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

        ignore = ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock")
        mock_isfile = (f::AbstractString) -> !(f in ignore) && (f == "/etc/localtime" || Original.isfile(f))
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
        ignore = ("/etc/timezone", "/etc/sysconfig/clock", "/etc/conf.d/clock", "/etc/localtime", "/usr/local/etc/localtime")
        mock_isfile = (f::AbstractString) -> !(f in ignore) && Original.isfile(f)
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
