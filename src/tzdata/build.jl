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


function build(
    version::AbstractString,
    regions::AbstractVector{<:AbstractString},
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="",
)
    if version == "latest"
        version = tzdata_latest_version()
        tzdata_hash = artifact_hash("tzdata$version", ARTIFACT_TOML)

        if tzdata_hash === nothing
            error("Latest tzdata is $version which is not present in the Artifacts.toml")
        end
    end

    artifact_dir = @artifact_str "tzdata$version"

    # TODO: Deprecate skipping tzdata installation step or use `nothing` instead
    if !isempty(tz_source_dir)
        @info "Installing $version tzdata region data"
        region_paths = vcat(
            joinpath.(artifact_dir, intersect!(readdir(artifact_dir), regions)),
            joinpath.(CUSTOM_REGION_DIR, CUSTOM_REGIONS),
        )
        for path in region_paths
            cp(path, joinpath(tz_source_dir, basename(path)), force=true)
        end
    end

    # TODO: Deprecate skipping conversion step or use `nothing` instead
    if !isempty(compiled_dir)
        @info "Converting tz source files into TimeZone data"
        tz_source = TZSource(readdir(tz_source_dir, join=true))
        compile(tz_source, compiled_dir)
    end

    return version
end

function build(version::AbstractString=tzdata_version())
    # Empty the compile directory so each build starts fresh.  Note that `serialized_cache_dir()`
    # creates the directory if it doesn't exist, so the `build()` call lower down will recreate
    # the directory after we delete it here.
    rm(compiled_dir(), recursive=true)

    version = build(version, REGIONS, tz_source_dir(), compiled_dir())
    return version
end
