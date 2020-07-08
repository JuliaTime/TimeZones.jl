using TimeZones.TZData: tzdata_url, LATEST_FILE, read_latest, REGIONS
using Pkg.Artifacts

@test tzdata_url("2016j") == "https://data.iana.org/time-zones/releases/tzdata2016j.tar.gz"
@test tzdata_url("latest") == "https://data.iana.org/time-zones/tzdata-latest.tar.gz"

mktempdir() do temp_dir
    file_path = ignore_output() do
        artifact"tzdata_latest"
    end

    @test isdir(file_path)
    @test basename(file_path) != basename(tzdata_url("latest"))

    last_modified = mtime(file_path)
    last_file_path = file_path

    # No need to ignore output as this should never trigger a download
    file_path = artifact"tzdata_latest"
    build("latest", REGIONS)
    
    @test file_path == last_file_path
    @test mtime(file_path) == last_modified

    # Validate the contents of the LATEST_FILE which will be automatically created when
    # downloading the latest data.
    @test isfile(LATEST_FILE)
    version, retrieved = read_latest(LATEST_FILE)
    @test occursin(r"\A(?:\d{2}){1,2}[a-z]?\z", version)
    @test isa(retrieved, DateTime)
end
