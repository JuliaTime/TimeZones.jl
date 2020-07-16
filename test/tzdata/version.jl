using TimeZones.TZData: ARCHIVE_DIR, TZDATA_VERSION_REGEX, TZDATA_NEWS_REGEX
using TimeZones.TZData: read_news, extract, tzdata_version_dir, tzdata_version_archive
using TimeZones.TZData: active_version, active_archive

use_artifacts = VERSION >= v"1.3"

if use_artifacts
    using TimeZones: @artifact_str
end

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


@static if use_artifacts
    artifact_dir = @artifact_str "tzdata$TZDATA_VERSION"
else
    archive = joinpath(ARCHIVE_DIR, "tzdata$TZDATA_VERSION.tar.gz")
end

mktempdir() do temp_dir
    # Read the first tzdata version
    if use_artifacts
        cp(joinpath(artifact_dir, "NEWS"), joinpath(temp_dir, "NEWS"))
    else
        extract(archive, temp_dir, "NEWS")
    end

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

if !use_artifacts
    @test tzdata_version_archive(archive) == TZDATA_VERSION
    @test_throws ProcessFailedException tzdata_version_archive(@__FILE__) == TZDATA_VERSION
end

# Active/built tzdata version
version = active_version()
@test version != "latest"  # Could happen if the logic to resolve the version fails
@test match(TZDATA_VERSION_REGEX, version) !== nothing

if !use_artifacts
    archive = active_archive()
    @test isfile(archive)
    @test dirname(archive) == ARCHIVE_DIR
    @test basename(archive) == "tzdata$version.tar.gz"
end
