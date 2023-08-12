using TimeZones.TZData: TZDATA_VERSION_REGEX, TZDATA_NEWS_REGEX
using TimeZones.TZData: read_news, tzdata_version_dir, tzdata_version_archive,
    tzdata_version

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

mktempdir() do temp_dir
    tzdata_archive_file = joinpath(
        _scratch_dir(),
        _archive_relative_dir(),
        basename(tzdata_url(TZDATA_VERSION)),
    )
    unpack(tzdata_archive_file, temp_dir, "NEWS")

    # Read the first tzdata version
    versions = read_news(joinpath(temp_dir, "NEWS"), 1)
    @test versions == [TZDATA_VERSION]

    # Read all tzdata versions
    # Note: Avoid testing for a complete set the NEWS file may be truncated in the future.
    year, letter = TZDATA_VERSION[1:end - 1], TZDATA_VERSION[end]
    latest_versions = map(c -> "$year$c", letter:-1:'a')

    versions = read_news(joinpath(temp_dir, "NEWS"))
    @test length(versions) > 1
    @test versions[1:length(latest_versions)] == latest_versions

    # Determine tzdata version from a directory
    @test tzdata_version_dir(temp_dir) == TZDATA_VERSION
    @test_throws ErrorException tzdata_version_dir(dirname(@__FILE__))
end

@testset "tzdata_version" begin
    withenv("JULIA_TZ_VERSION" => nothing) do
        version = tzdata_version()
        @test version != "latest"
        @test version == TZJData.TZDATA_VERSION
    end

    withenv("JULIA_TZ_VERSION" => TZDATA_VERSION) do
        @test tzdata_version() == TZDATA_VERSION
    end

    withenv("JULIA_TZ_VERSION" => "latest") do
        version = tzdata_version()
        @test version != "latest"
        @test occursin(TZDATA_VERSION_REGEX, version)
    end
end
