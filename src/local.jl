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

    @static if Sys.isapple()
        name = @mock read(`systemsetup -gettimezone`, String)  # Appears to only work as root
        if startswith(name, "Time Zone: ")
            name = strip(replace(name, "Time Zone: " => ""))
        else
            # link will be something like /usr/share/zoneinfo/Europe/Warsaw
            name = @mock readlink("/etc/localtime")
            name = match(r"(?<=zoneinfo/).*$", name).match
        end
        return TimeZone(name, mask)
    elseif Sys.isunix()
        name = ""

        # Try getting the time zone from the "TZ" environment variable
        # http://linux.die.net/man/3/tzset
        if haskey(ENV, "TZ")
            name = ENV["TZ"]

            # When the TZ format starts with a colon this indicates that the time zone information
            # should be read from a file.
            if startswith(name, ':')
                name = name[2:end]
            else
                return parse_tz_format(name)
            end

            if startswith(name, '/')
                return @mock open(name) do f
                    read_tzfile(f, "local")
                end
            else
                # Relative name matches pre-compiled time zone name
                istimezone(name, mask) && return TimeZone(name, mask)

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

        # Look for distribution specific configuration files that contain the time zone name.

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

        # systemd distributions use symlinks that include the zone name,
        # see manpage of localtime(5) and timedatectl(1)
        link = "/etc/localtime"
        if @mock islink(link)
            filepath = @mock readlink(link)
            pos = findnext(isequal('/'), filepath, 1)

            while pos !== nothing
                name = SubString(filepath, pos + 1)
                istimezone(name, mask) && return TimeZone(name, mask)
                pos = findnext(isequal('/'), filepath, pos + 1)
            end
        end

        # No explicit setting existed. Use localtime
        for filepath in ("/etc/localtime", "/usr/local/etc/localtime")
            (@mock isfile(filepath)) || continue
            return @mock open(filepath) do f
                read_tzfile(f, "local")
            end
        end
    elseif Sys.iswindows()
        # Windows powershell should be available on Windows 7 and above
        win_name = strip(@mock read(`powershell -Command "[TimeZoneInfo]::Local.Id"`, String))

        if haskey(WINDOWS_TRANSLATION, win_name)
            return TimeZone(WINDOWS_TRANSLATION[win_name], mask)
        else
            error("unable to translate to POSIX time zone name from: \"$win_name\"")
        end
    end

    error("Failed to find local time zone")
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
    m = match(TZ_REGEX, str)

    # Currently the only supported TZ format is reading time zone information from
    # a file.
    if m === nothing
        throw(ArgumentError("Unhandled TZ environment variable format: \"$str\""))
    end

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

    FixedTimeZone(name, offset)
end
