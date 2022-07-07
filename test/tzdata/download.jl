using TimeZones.TZData: latest_file_path, read_latest
using TimeZones.TZData: tzdata_latest_version, tzdata_versions

@testset "tzdata_versions" begin
    versions = tzdata_versions()
    @test first(versions) == "93g"  # Earliest release
    @test "2016j" in versions
end

@testset "tzdata_latest_version" begin
    @test occursin(r"^(?:\d{2}){1,2}[a-z]?$", tzdata_latest_version())

    # Validate the contents of the latest file which will be automatically created when
    # downloading the latest data.
    @test isfile(latest_file_path())
    version, retrieved = read_latest(latest_file_path())
    @test occursin(r"\A(?:\d{2}){1,2}[a-z]?\z", version)
    @test isa(retrieved, DateTime)
end
