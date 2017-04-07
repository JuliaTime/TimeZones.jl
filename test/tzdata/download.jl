import TimeZones.TZData: tzdata_url, tzdata_download, isarchive

@test tzdata_url("2016j") == "https://www.iana.org/time-zones/repository/releases/tzdata2016j.tar.gz"
@test tzdata_url("latest") == "https://www.iana.org/time-zones/repository/tzdata-latest.tar.gz"

# Note: Try to keep the number of `tzdata_download` calls low to avoid unnecessary network traffic
mktempdir() do temp_dir
    file_path = ignore_output() do
        tzdata_download("latest", temp_dir)
    end

    @test isfile(file_path)
    @test isarchive(file_path)
    @test basename(file_path) != basename(tzdata_url("latest"))

    last_modified = mtime(file_path)
    last_file_path = file_path

    # No need to ignore output as this should never trigger a download
    file_path = tzdata_download("latest", temp_dir)

    @test file_path == last_file_path
    @test mtime(file_path) == last_modified
end
