function fixed_timezones()
    fixedzones = Dict{AbstractString, TimeZone}()
    # UTC equivalent times
    utc = FixedTimeZone("UTC", 0)
    for name in ("UTC", "Universal", "Zulu", "Etc/UTC", "Etc/Universal", "Etc/Zulu")
        fixedzones[name] = utc
    end
    # GMT equivalent times
    gmt = FixedTimeZone("GMT", 0)
    for name in ("GMT", "Etc/GMT", "Etc/GMT+0", "Etc/GMT-0")
        fixedzones[name] = gmt
    end
    # GMT-14 to GMT-1 and GMT+1 to GMT+12
    for i in [-14:-1; 1:12]
        abbr = @sprintf("GMT%+d", i)
        fixedzones["Etc/$abbr"] = FixedTimeZone(abbr, -i * 3600)
    end
    return fixedzones
end
