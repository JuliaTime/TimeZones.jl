# Determine the local system's time zone
# Based upon Python's tzlocal https://pypi.python.org/pypi/tzlocal
using Mocking: Mocking, @mock

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
        # https://linux.die.net/man/3/tzset
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
            force_tzfile = false

            # If the TZ format starts with a colon we'll prefer using the time zone
            # information from the specified file.
            if startswith(name, ':')
                name = name[2:end]  # Either a relative or absolute path
                force_tzfile = true
            else
                # Check if name matches pre-compiled time zone
                istimezone(name, mask) && return TimeZone(name, mask)
            end

            if startswith(name, '/')
                return @mock open(name) do f
                    TZFile.read(f)(something(_path_tz_name(name, mask), "local"))
                end
            else
                # The system time zone directory used depends on the (g)libc version
                tzdirs = ["/usr/lib/zoneinfo", "/usr/share/zoneinfo"]
                haskey(ENV, "TZDIR") && pushfirst!(tzdirs, ENV["TZDIR"])

                for dir in tzdirs
                    filepath = joinpath(dir, name)
                    (@mock isfile(filepath)) || continue
                    return @mock open(filepath) do f
                        TZFile.read(f)(name)
                    end
                end

                if !force_tzfile
                    return parse_tz_format(name)
                else
                    error("Unable to locate tzfile: $name")
                end
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
                TZFile.read(f)("local")
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


"""
    parse_tz_format(str) -> TimeZone

Parse the time zone format typically provided via the "TZ" environment variable. Details on
the format can be found under the man page for
[tzset](https://man7.org/linux/man-pages/man3/tzset.3.html).
"""
function parse_tz_format(str::AbstractString)
    x = _parsesub_tz(str)
    if x isa Tuple
        tz, i = x
        return tz
    else
        throw(ParseNextError("Unhandled TZ environment variable. $(x.msg)", x.str, x.s, x.e))
    end
end

"""
    tryparse_tz_format(str) -> Union{TimeZone, Nothing}

Like `parse_tz_format`, but returns either a value of the `TimeZone`, or `nothing` if
the string does not contain a valid format.
"""
function tryparse_tz_format(str::AbstractString)
    x = _parsesub_tz(str)
    if x isa Tuple
        tz, i = x
        return tz
    else
        return nothing
    end
end
