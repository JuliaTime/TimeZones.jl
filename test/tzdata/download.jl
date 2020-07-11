using TimeZones.TZData: tzdata_url, tzdata_download, isarchive, LATEST_FILE, read_latest, REGIONS, latest_version,
    tzdata_version
using Dates
if VERSION >= v"1.4"
    using Pkg.Artifacts
end


@test tzdata_url("2016j") == "https://data.iana.org/time-zones/releases/tzdata2016j.tar.gz"
@test tzdata_url("latest") == "https://data.iana.org/time-zones/tzdata-latest.tar.gz"

# Note: Try to keep the number of `tzdata_download` calls low to avoid unnecessary network traffic
mktempdir() do temp_dir
    file_path = ignore_output() do
        if VERSION >= v"1.4"
            build(tzdata_version(), REGIONS, "")
            latest_tzdata = "tzdata_$(latest_version())"
            @artifact_str latest_tzdata
        else
            tzdata_download("latest", temp_dir)
        end
    end

    if VERSION >= v"1.4"
        @test isdir(file_path)
    else
        @test isfile(file_path)
        @test isarchive(file_path)
    end
    @test basename(file_path) != basename(tzdata_url("latest"))

    last_modified = mtime(file_path)
    last_file_path = file_path

    # No need to ignore output as this should never trigger a download
    if VERSION >= v"1.4"
        file_path = @artifact_str "tzdata_$(latest_version())"
    else
        file_path = tzdata_download("latest", temp_dir)
    end

    @test file_path == last_file_path
    @test mtime(file_path) == last_modified

    # Validate the contents of the LATEST_FILE which will be automatically created when
    # downloading the latest data.
    @test isfile(LATEST_FILE)
    version, retrieved = read_latest(LATEST_FILE)
    @test occursin(r"\A(?:\d{2}){1,2}[a-z]?\z", version)
    @test isa(retrieved, DateTime)
end
