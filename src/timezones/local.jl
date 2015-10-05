# Determine the local systems timezone
# Based upon Python's tzlocal https://pypi.python.org/pypi/tzlocal

@osx_only function localzone()
    name = readall(`systemsetup -gettimezone`)
    if contains(name, "Time Zone: ")
        name = strip(replace(name, "Time Zone: ", ""))
    else
        # link will be something like /usr/share/zoneinfo/Europe/Warsaw
        name = readlink("/etc/localtime")
        name = match(r"(?<=zoneinfo/).*$", name).match
    end
    return TimeZone(name)
end

@linux_only function localzone()
    name = ""
    validnames = timezone_names()

    # Try getting the time zone from the "TZ" environment variable
    # http://linux.die.net/man/3/tzset
    if haskey(ENV, "TZ")
        name = ENV["TZ"]
        startswith(name, ':') || error("Currently only support filespec for TZ variable")
        name = name[2:end]

        if startswith(name, '/')
            return open(name) do f
                read_tzfile(f, "local")
            end
        else
            # Relative name matches pre-compiled timezone name
            name in validnames && return TimeZone(name)

            # The system timezone directory used depends on the (g)libc version
            tzdirs = ["/usr/lib/zoneinfo", "/usr/share/zoneinfo"]
            haskey(ENV, "TZDIR") && unshift!(tzdirs, ENV["TZDIR"])

            for dir in tzdirs
                filepath = joinpath(dir, name)
                isfile(filepath) || continue
                return open(filepath) do f
                    read_tzfile(f, name)
                end
            end

            throw(SystemError("unable to locate tzfile: $name"))
        end
    end

    # Look for distribution specific configuration files that contain the timezone name.

    filename = "/etc/timezone"
    if isfile(filename)
        open(filename) do file
            name = readall(file)

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
        isfile(filepath) || continue
        open(filepath) do file
            for line in readlines(file)
                matched = match(zone_re, line)
                if matched != nothing
                    name = matched.captures["name"]
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
    if islink(link)
        filepath = readlink(link)
        start = search(filepath, '/')

        while start != 0
            name = filepath[(start + 1):end]
            name in validnames && return TimeZone(name)
            start = search(filepath, '/', start + 1)
        end
    end

    # No explicit setting existed. Use localtime
    for filepath in ("/etc/localtime", "/usr/local/etc/localtime")
        isfile(filepath) || continue
        return open(filepath) do f
            read_tzfile(f, "local")
        end
    end

    error("Failed to find local timezone")
end

@windows_only function localzone()
    isfile(TRANSLATION_FILE) || error("Missing Windows to POSIX timezone translation ",
        "file. Try running Pkg.build(\"TimeZones\")")

    translation = open(TRANSLATION_FILE, "r") do fp
        deserialize(fp)
    end

    # Windows powershell should be available on Windows 7 and above
    winzone = strip(readall(`powershell -Command "[TimeZoneInfo]::Local.Id"`))
    if haskey(translation, winzone)
        return TimeZone(translation[winzone])
    else
        error("unable to translate to POSIX timezone name: $winzone")
    end
end
