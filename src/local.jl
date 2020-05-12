# Determine the local system's time zone
# Based upon Python's tzlocal https://pypi.python.org/pypi/tzlocal
using Mocking: Mocking, @mock

if Sys.iswindows()
    import TimeZones.WindowsTimeZoneIDs: WINDOWS_TRANSLATION
end

"""
    localzone() -> TimeZone

Returns a `TimeZone` object that is equivalent to the system's current time zone.
"""
function localzone()
    # Only allow creating a TimeZone using standard and legacy IANA time zone database
    # names. We allow the use of legacy names here as most operating systems still use the
    # legacy names.
    mask = Class(:STANDARD) | Class(:LEGACY)

    @static if Sys.isunix()
        name = ""

        # Try getting the time zone from the "TZ" environment variable
        # http://linux.die.net/man/3/tzset
        #
        # Note: The macOS man page tzset(3) states some additional information about the
        # colon being optional:
        #
        # > If TZ appears in the environment and its value begins with a colon (`:'), the
        # > rest of its value is used as a pathname of a tzfile(5)-format file from which to
        # > read the time conversion information. If the first character of the pathname is
        # > a slash (`/'), it is used as an absolute pathname; otherwise, it is used as a
        # > pathname relative to the system time conversion information directory.
        # >
        # > If its value does not begin with a colon, it is first used as the pathname of a
        # > file (as described above) from which to read the time conversion information. If
        # > that file cannot be read, the value is then interpreted as a direct
        # > specification (the format is described below) of the time conversion
        # > information.
        if haskey(ENV, "TZ")
            name = ENV["TZ"]

            # If the TZ format starts with a colon we'll prefer using the time zone
            # information from the specified file.
            if startswith(name, ':')
                name = name[2:end]  # Name is either an relative or absolute path
            else
                tz = tryparse_tz_format(name)
                tz !== nothing && return tz

                # Name matches pre-compiled time zone name
                istimezone(name, mask) && return TimeZone(name, mask)
            end

            if startswith(name, '/')
                return @mock open(name) do f
                    read_tzfile(f, something(_path_tz_name(name, mask), "local"))
                end
            else
                # The system time zone directory used depends on the (g)libc version
                tzdirs = ["/usr/lib/zoneinfo", "/usr/share/zoneinfo"]
                haskey(ENV, "TZDIR") && pushfirst!(tzdirs, ENV["TZDIR"])

                for dir in tzdirs
                    filepath = joinpath(dir, name)
                    (@mock isfile(filepath)) || continue
                    return @mock open(filepath) do f
                        read_tzfile(f, name)
                    end
                end

                error("unable to locate tzfile: $name")
            end
        end

        # Look for Linux distribution configuration files that contain the time zone name.
        # Since we don't expect these files on macOS we'll avoid doing these checks to
        # improve performance.
        @static if Sys.islinux()
            filename = "/etc/timezone"
            if @mock isfile(filename)
                @mock open(filename) do file
                    name = read(file, String)

                    # Get rid of host definitions and comments:
                    name = strip(replace(name, r"#.*" => ""))
                    name = replace(name, ' ' => '_')
                end

                istimezone(name, mask) && return TimeZone(name, mask)
            end

            # CentOS has a ZONE setting in /etc/sysconfig/clock,
            # OpenSUSE has a TIMEZONE setting in /etc/sysconfig/clock and
            # Gentoo has a TIMEZONE setting in /etc/conf.d/clock

            zone_re = r"(TIME)?ZONE\s*=\s*\"(?<name>.*?)\""
            for filepath in ("/etc/sysconfig/clock", "/etc/conf.d/clock")
                (@mock isfile(filepath)) || continue
                @mock open(filepath) do file
                    for line in readlines(file)
                        matched = match(zone_re, line)
                        if matched != nothing
                            name = matched["name"]
                            name = replace(name, ' ' => '_')
                            break
                        end
                    end
                end

                istimezone(name, mask) && return TimeZone(name, mask)
            end
        end

        # systemd distributions use symlinks that include the zone name,
        # see man page of localtime(5) and timedatectl(1)
        link = "/etc/localtime"
        if @mock islink(link)
            target = @mock readlink(link)
            name = _path_tz_name(target, mask)
            name !== nothing && return TimeZone(name, mask)
        end

        # No explicit setting existed. Use localtime
        for filepath in ("/etc/localtime", "/usr/local/etc/localtime")
            (@mock isfile(filepath)) || continue
            return @mock open(filepath) do f
                read_tzfile(f, "local")
            end
        end
    elseif Sys.iswindows()
        # The Windows Time Zone Utility (tzutil) is pre-installed from Windows XP and later.
        # This approach was used as it is the fastest without without adding additional
        # package dependencies.
        #
        # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tzutil
        # https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh875624(v=ws.11)
        #
        # Alternative approaches:
        # - Call .NET via Powershell: `powershell -Command "[TimeZoneInfo]::Local.Id"`
        # - Read the Windows registry
        win_name = @mock read(`tzutil /g`, String)

        if haskey(WINDOWS_TRANSLATION, win_name)
            return TimeZone(WINDOWS_TRANSLATION[win_name], mask)
        else
            error("unable to translate to POSIX time zone name from: \"$win_name\"")
        end
    end

    error("Failed to find local time zone")
end



# Extract a time zone name from a path.
# e.g. "/usr/share/zoneinfo/Europe/Warsaw" becomes "Europe/Warsaw"
function _path_tz_name(path::AbstractString, mask::Class=Class(:ALL))
    i = 0
    while i !== nothing
        name = SubString(path, i + 1)
        istimezone(name, mask) && return name
        i = findnext(isequal('/'), path, i + 1)
    end

    return nothing
end


# Using conditional expressions `(?(condition)yes-regexp)` as control flow to indicate that
# that a captured group is dependent on a previous group begin matched. This could also be
# accomplished using nested groups.
const TZ_REGEX = r"""
    ^
    (?<name>[a-zA-Z]{3,})?
    (?(name)(?<sign>[+-]))?
    (?(name)(?<hour>\d+))?
    (?(hour)\:(?<minute>\d+))?
    (?(minute)\:(?<second>\d+))?
    $
    """x

"""
    parse_tz_format(str) -> TimeZone

Parse the time zone format typically provided via the "TZ" environment variable. Details on
the format can be found under the man page for
[tzset](http://man7.org/linux/man-pages/man3/tzset.3.html).

Currently this function handles only the first format which is a fixed time zone without
daylight saving time.
"""
function parse_tz_format(str::AbstractString)
    tz = tryparse_tz_format(str)

    if tz !== nothing
        return tz
    else
        throw(ArgumentError("Unhandled TZ environment variable format: \"$str\""))
    end
end

"""
    tryparse_tz_format(str) -> Union{TimeZone, Nothing}

Like `parse_tz_format`, but returns either a value of the `TimeZone`, or `nothing` if
the string does not contain a valid format.
"""
function tryparse_tz_format(str::AbstractString)
    m = match(TZ_REGEX, str)

    # Currently the only supported TZ format is reading time zone information from
    # a file.
    m === nothing && return nothing

    parse_digits(s) = s === nothing ? 0 : Base.parse(Int, s)

    name = m[:name] === nothing ? "UTC" : m[:name]

    # Note: positive indidates the local time zone is west of the Prime Meridian and
    # negative if it is east. This is the opposite of what FixedTimeZone expects.
    sign_val = m[:sign] == "-" ? 1 : -1

    # The tzset specification indicates that hours must be between 0 and 24 and minutes and
    # seconds 0 and 59. If values exceed these bounds they are clamped rather than treating
    # the entire format as invalid.
    hour = clamp(parse_digits(m[:hour]), 0, 24)
    minute = clamp(parse_digits(m[:minute]), 0, 59)
    second = clamp(parse_digits(m[:second]), 0, 59)

    offset = sign_val * (hour * 3600 + minute * 60 + second)

    return FixedTimeZone(name, offset)
end
