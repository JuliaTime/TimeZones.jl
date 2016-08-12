# Determine the local system's time zone
# Based upon Python's tzlocal https://pypi.python.org/pypi/tzlocal
import Compat: @static, is_apple, is_unix, is_windows, readstring
using Mocking

"""
    localzone() -> TimeZone

Returns a `TimeZone` object that is equivalent to the system's current time zone.
"""
function localzone()
    @static if is_apple()
        name = @mock readstring(`systemsetup -gettimezone`)  # Appears to only work as root
        if contains(name, "Time Zone: ")
            name = strip(replace(name, "Time Zone: ", ""))
        else
            # link will be something like /usr/share/zoneinfo/Europe/Warsaw
            name = @mock readlink("/etc/localtime")
            name = match(r"(?<=zoneinfo/).*$", name).match
        end
        return TimeZone(name)
    elseif is_unix()
        name = ""
        validnames = timezone_names()

        # Try getting the time zone from the "TZ" environment variable
        # http://linux.die.net/man/3/tzset
        if haskey(ENV, "TZ")
            name = ENV["TZ"]
            startswith(name, ':') || error("Currently only support filespec for TZ variable")
            name = name[2:end]

            if startswith(name, '/')
                return @mock open(name) do f
                    read_tzfile(f, "local")
                end
            else
                # Relative name matches pre-compiled time zone name
                name in validnames && return TimeZone(name)

                # The system time zone directory used depends on the (g)libc version
                tzdirs = ["/usr/lib/zoneinfo", "/usr/share/zoneinfo"]
                haskey(ENV, "TZDIR") && unshift!(tzdirs, ENV["TZDIR"])

                for dir in tzdirs
                    filepath = joinpath(dir, name)
                    (@mock isfile(filepath)) || continue
                    return @mock open(filepath) do f
                        read_tzfile(f, name)
                    end
                end

                throw(SystemError("unable to locate tzfile: $name"))
            end
        end

        # Look for distribution specific configuration files that contain the time zone name.

        filename = "/etc/timezone"
        if @mock isfile(filename)
            @mock open(filename) do file
                name = readstring(file)

                # Get rid of host definitions and comments:
                name = strip(replace(name, r"#.*", ""))
                name = replace(name, ' ', '_')
            end

            name in validnames && return TimeZone(name)
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
                        name = replace(name, ' ', '_')
                        break
                    end
                end
            end

            name in validnames && return TimeZone(name)
        end

        # systemd distributions use symlinks that include the zone name,
        # see manpage of localtime(5) and timedatectl(1)
        link = "/etc/localtime"
        if @mock islink(link)
            filepath = @mock readlink(link)
            start = search(filepath, '/')

            while start != 0
                name = filepath[(start + 1):end]
                name in validnames && return TimeZone(name)
                start = search(filepath, '/', start + 1)
            end
        end

        # No explicit setting existed. Use localtime
        for filepath in ("/etc/localtime", "/usr/local/etc/localtime")
            (@mock isfile(filepath)) || continue
            return @mock open(filepath) do f
                read_tzfile(f, "local")
            end
        end
    elseif is_windows()
        isfile(WIN_TRANSLATION_FILE) || error("Missing Windows to POSIX time zone translation ",
            "file. Try running Pkg.build(\"TimeZones\")")

        translation = open(WIN_TRANSLATION_FILE, "r") do fp
            deserialize(fp)
        end

        # Windows powershell should be available on Windows 7 and above
        win_name = strip(@mock readstring(`powershell -Command "[TimeZoneInfo]::Local.Id"`))
        if haskey(translation, win_name)
            posix_name = translation[win_name]

            # Translation dict includes Etc time zones which we currently are not supporting
            # since they are deemed historical. To ensure compatibility with the translation
            # dict we will manually convert these fixed time zones.
            if startswith(posix_name, "Etc/GMT")
                name = replace(posix_name, r"Etc/GMT0?", "UTC")

                # Note: Etc/GMT[+-] are reversed compared to UTC[+-]
                if contains(name, "+")
                    name = replace(name, "+", "-")
                else
                    name = replace(name, "-", "+")
                end

                return FixedTimeZone(name)
            else
                return TimeZone(posix_name)
            end
        else
            error("unable to translate to POSIX time zone name from: \"$win_name\"")
        end
    end

    error("Failed to find local time zone")
end
