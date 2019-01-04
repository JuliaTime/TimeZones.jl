using TimeZones.TZData: ARCHIVE_DIR, isarchive, readarchive, extract

const ARCHIVE_PATH = let
    archives = filter(file -> endswith(file, "tar.gz"), readdir(ARCHIVE_DIR))
    isempty(archives) && error("Unable to run archive tests without first running Pkg.build(\"TimeZones\")")
    joinpath(ARCHIVE_DIR, first(archives))
end

@test isarchive(ARCHIVE_PATH)
@test !isarchive(@__FILE__)

files = readarchive(ARCHIVE_PATH)
@test !isempty(files)
@test_throws ErrorException readarchive(@__FILE__)

mktempdir() do temp_dir
    @test isempty(readdir(temp_dir))

    # Extract entire archive
    extract(ARCHIVE_PATH, temp_dir)
    @test !isempty(readdir(temp_dir))

    files = readarchive(ARCHIVE_PATH)
    for file in files
        rm(joinpath(temp_dir, file))
    end

    # Extract a single file
    extract(ARCHIVE_PATH, temp_dir, files[1])
    @test readdir(temp_dir) == files[1:1]

    # Extract multiple files and overwrite the first file
    extract(ARCHIVE_PATH, temp_dir, files[1:2])
    @test readdir(temp_dir) == files[1:2]

    # Attempt to decompress a non-archive
    @test_throws ErrorException extract(@__FILE__, temp_dir)
end
