fixedzones = TimeZones.fixed_timezones()

for name in ("UTC", "Universal", "Zulu", "Etc/UTC", "Etc/Universal", "Etc/Zulu")
    tz = fixedzones[name]
    @test tz == FixedTimeZone("UTC", 0)
end

for name in ("GMT", "Etc/GMT", "Etc/GMT+0", "Etc/GMT-0")
    tz = fixedzones[name]
    @test tz == FixedTimeZone("GMT", 0)
end

for i in [-14:-1; 1:12]
    abbr = @sprintf("GMT%+d", i)
    name = "Etc/$abbr"
    tz = fixedzones[name]
    @test tz == FixedTimeZone(abbr, -i * 3600)
end
