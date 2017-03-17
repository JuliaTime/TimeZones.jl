import TimeZones.TZData: TZDATA_VERSION_REGEX, TZDATA_NEWS_REGEX

for year = ("12", "1234"), letter = ("", "z")
    version = year * letter
    @test match(TZDATA_VERSION_REGEX, version).match == version
    @test match(TZDATA_VERSION_REGEX, "tzdata$version.tar.gz").match == version
end

for year = ("1", "123", "12345"), letter = ("", "a")
    version = year * letter
    @test match(TZDATA_VERSION_REGEX, version) === nothing
    @test match(TZDATA_VERSION_REGEX, "tzdata$version.tar.gz") === nothing
end

@test match(TZDATA_NEWS_REGEX, "Release 92")[:version] == "92"
@test match(TZDATA_NEWS_REGEX, "Release 92c")[:version] == "92c"
@test match(TZDATA_NEWS_REGEX, "Release data94a")[:version] == "94a"
@test match(TZDATA_NEWS_REGEX, "Release code94c") === nothing
@test match(TZDATA_NEWS_REGEX, "Release code95f-data95j")[:version] == "95j"
@test match(TZDATA_NEWS_REGEX, "Release data1996m")[:version] == "1996m"
@test match(TZDATA_NEWS_REGEX, "Release code1996n") === nothing
@test match(TZDATA_NEWS_REGEX, "Release code1996o-data1996n")[:version] == "1996n"
@test match(TZDATA_NEWS_REGEX, "Release 1997a")[:version] == "1997a"

@test match(TZDATA_NEWS_REGEX, "Release 1") === nothing
@test match(TZDATA_NEWS_REGEX, "Release 199") === nothing
@test match(TZDATA_NEWS_REGEX, "Release 19999") === nothing
