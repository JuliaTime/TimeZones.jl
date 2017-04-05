import TimeZones: ARCHIVE_DIR
import TimeZones.TZData: read_news, extract, tzdata_version_dir, tzdata_version_archive

archive = joinpath(ARCHIVE_DIR, "tzdata$TZDATA_VERSION.tar.gz")

mktempdir() do temp_dir
    # Read the first tzdata version
    extract(archive, temp_dir, "NEWS")
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

@test tzdata_version_archive(archive) == TZDATA_VERSION
@test_throws ErrorException tzdata_version_archive(@__FILE__) == TZDATA_VERSION
