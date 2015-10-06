zonenames = TimeZones.timezone_names()

for i in ("UTC", "Universal", "Zulu", "Etc/UTC", "Etc/Universal", "Etc/Zulu")
    @test i in zonenames
    fixedzone = TimeZone(i)
    @test typeof(fixedzone) <: FixedTimeZone
    @test fixedzone.name == :UTC
    @test fixedzone.offset.utc == Dates.Second(0)
end

for i in ("GMT", "Etc/GMT", "Etc/GMT+0", "Etc/GMT-0")
    @test i in zonenames
    fixedzone = TimeZone(i)
    @test typeof(fixedzone) <: FixedTimeZone
    @test fixedzone.name == :GMT
    @test fixedzone.offset.utc == Dates.Second(0)
end

for i in 1:12
    zonename = "GMT+$i"
    @test "Etc/$zonename" in zonenames
    fixedzone = TimeZone("Etc/$zonename")
    @test typeof(fixedzone) <: FixedTimeZone
    @test fixedzone.name == Symbol("$zonename")
    @test fixedzone.offset.utc == Dates.Second(i*(-3600))
end

for i in 1:14
    zonename = "GMT-$i"
    @test "Etc/$zonename" in zonenames
    fixedzone = TimeZone("Etc/$zonename")
    @test typeof(fixedzone) <: FixedTimeZone
    @test fixedzone.name == Symbol("$zonename")
    @test fixedzone.offset.utc == Dates.Second(i*3600)
end
