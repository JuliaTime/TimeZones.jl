function fixed_timezones()
    fixedzones = Dict{AbstractString, TimeZone}()
    # utc equivalent times
    utc = FixedTimeZone("UTC", 0)
    for zone in ("UTC", "Universal", "Zulu", "Etc/UTC", "Etc/Universal", "Etc/Zulu")
        fixedzones[zone] = utc
    end
    # GMT equivalent times
    gmt = FixedTimeZone("GMT", 0)
    for zone in ("GMT", "Etc/GMT", "Etc/GMT+0", "Etc/GMT-0")
        fixedzones[zone] = gmt
    end
    # GMT+1 to GMT+12
    for i in 1:12
        zone = "GMT+$i"
        fixedzones["Etc/$zone"] = FixedTimeZone(zone, -i*3600)
    end
    # GMT-1 to GMT-14
    for i in 1:14
        zone = "GMT-$i"
        fixedzones["Etc/$zone"] = FixedTimeZone(zone, i*3600)
    end
    return fixedzones
end
