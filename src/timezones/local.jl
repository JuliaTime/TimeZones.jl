# Determine the local systems timezone
# Based upon Python's tzlocal https://pypi.python.org/pypi/tzlocal

function get_localzone()
    @windows? _get_localzone_windows():(
        @osx? _get_localzone_mac():(
            _get_localzone_unix()
        )
    )
end

function _get_localzone_mac()
    zone = readall(`systemsetup -gettimezone`)
    if contains(zone, "Time Zone: ")
        zone = strip(replace(zone, "Time Zone: ", ""))
    else
        zone = readlink("/etc/localtime")
        # link will be something like /usr/share/zoneinfo/America/Winnipeg
        zone = match(r"(?<=zoneinfo/).*$", zone).match
    end
    return zone
end

function _get_localzone_unix()
    validnames = timezone_names()

    # Try getting the time zone "TZ" environment variable
    # http://linux.die.net/man/3/tzset
    zone = Nullable{AbstractString}(get(ENV, "TZ", nothing))
    if !isnull(zone)
        zone_str = get(zone)
        if startswith(zone_str,':')
            zone_str = zone_str[2:end]
        end
        zone_str in validnames && return zone_str

        # TODO Read the tzfile to get the timezone

        error("Failed to resolve local timezone from \"TZ\" environment variable. ",
            "Only currently support timezone names as the \"TZ\" environment variable")
    end

    # Look for distribution specific configuration files
    # that contain the timezone name.

    filename = "/etc/timezone"
    if isfile(filename)
        zone = ""
        open(filename) do file
            zone = readall(file)
            # Get rid of host definitions and comments:
            zone = strip(replace(zone, r"#.*", ""))
            zone = replace(zone, ' ', '_')
        end
        zone in validnames && return zone
    end

    # CentOS has a ZONE setting in /etc/sysconfig/clock,
    # OpenSUSE has a TIMEZONE setting in /etc/sysconfig/clock and
    # Gentoo has a TIMEZONE setting in /etc/conf.d/clock

    zone_re = r"(?:TIME)?ZONE\s*=\s*\"(.*?)\""
    for filename in ("/etc/sysconfig/clock", "/etc/conf.d/clock")
        isfile(filename) || continue
        file = open(filename)
        try # Make sure we close the file
            for line in readlines(file)
                matched = match(zone_re, line)
                if matched != nothing
                    zone = matched.captures[1]
                    zone = replace(zone, ' ', '_')

                    zone in validnames && return zone
                end
            end
        finally
            close(file)
        end
    end

    # systemd distributions use symlinks that include the zone name,
    # see manpage of localtime(5) and timedatectl(1)
    link = "/etc/localtime"
    if islink(link)
        zone = readlink(link)
        start = search(zone, '/')

        while start != 0
            zone = zone[(start+1):end]

            zone in validnames && return zone

            start = search(zone, '/')
        end
    end

    # TODO No explicit setting existed. Use localtime

    error("Failed to find local timezone")
end

function _get_localzone_windows()
    isfile(TRANSLATION_FILE) ||
        error("Windows zones not found. Try running Pkg.build(\"TimeZones\")")

    win_tz_dict = nothing
    open(TRANSLATION_FILE, "r") do fp
        win_tz_dict = deserialize(fp)
    end

    winzone = strip(readall(`powershell -Command "[TimeZoneInfo]::Local.Id"`))
    if haskey(win_tz_dict, winzone)
        timezone = win_tz_dict[winzone]
    else
        error("Failed to determine your Windows timezone. ",
            "Uses powershell, should work on windows 7 and above")
    end

    return timezone
end
