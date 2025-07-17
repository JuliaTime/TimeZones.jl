# The default tz source files we care about. See "ftp://ftp.iana.org/tz/data/Makefile"
# "PRIMARY_YDATA" for listing of tz source files to include.
const STANDARD_REGIONS = [
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica", "utc",
]

# Legacy tz source files TimeZones.jl typically ignores ("YDATA" in Makefile).
const LEGACY_REGIONS = [
    "pacificnew", "etcetera", "backward",
]

# Note: The "utc" region is a made up tz source file and isn't included in the archives.
const CUSTOM_REGION_DIR = joinpath(@__DIR__, "..", "..", "deps", "tzsource_custom")
const CUSTOM_REGIONS = [
    "utc",
]

const REGIONS = [STANDARD_REGIONS; LEGACY_REGIONS]


_archive_relative_dir() = "archive"
_tz_source_relative_dir(version::AbstractString) = joinpath("tzsource", version)
_compiled_relative_dir(version::AbstractString) = joinpath("compiled", "tzjf", "v$(TZJFile.DEFAULT_VERSION)", version)

function build(version::AbstractString, working_dir::AbstractString)
    tzdata_archive_dir = joinpath(working_dir, _archive_relative_dir())
    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(version))
    compiled_dir = joinpath(working_dir, _compiled_relative_dir(version))

    url = tzdata_url(version)
    tzdata_archive_file = joinpath(tzdata_archive_dir, basename(url))
    if !isfile(tzdata_archive_file)
        @info "Downloading tzdata $version archive"
        mkpath(tzdata_archive_dir)
        download(url, tzdata_archive_file)
    end

    if !isdir(tz_source_dir)
        @info "Decompressing tzdata $version region data"
        isarchive(tzdata_archive_file) || error("Invalid archive: $tzdata_archive_file")
        mkpath(tz_source_dir)

        # TODO: Confirm that "utc" was ever included in the tzdata archives
        regions = intersect!(list(tzdata_archive_file), REGIONS)
        unpack(tzdata_archive_file, tz_source_dir, regions)

        for custom_region in CUSTOM_REGIONS
            cp(joinpath(CUSTOM_REGION_DIR, custom_region), joinpath(tz_source_dir, custom_region))
            push!(regions, custom_region)
        end
    else
        regions = intersect!(readdir(tz_source_dir), REGIONS)
    end

    if !isdir(compiled_dir) || isempty(readdir(compiled_dir))
        @info "Compiling tzdata $version region data"
        mkpath(compiled_dir)
        tz_source = TZSource(joinpath.(tz_source_dir, regions))
        compile(tz_source, compiled_dir)
    end

    return compiled_dir
end

function cleanup(version::AbstractString, working_dir::AbstractString)
    tzdata_archive_file = joinpath(working_dir, _archive_relative_dir(), basename(tzdata_url(version)))
    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(version))
    compiled_dir = joinpath(working_dir, _compiled_relative_dir(version))

    isfile(tzdata_archive_file) && rm(tzdata_archive_file)
    isdir(tz_source_dir) && rm(tz_source_dir; recursive=true)
    isdir(compiled_dir) && rm(compiled_dir; recursive=true)

    return nothing
end
