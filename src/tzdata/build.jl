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
const CUSTOM_REGIONS = [
    "utc",
]

const REGIONS = [STANDARD_REGIONS; LEGACY_REGIONS]


function build(
    version::AbstractString,
    regions::AbstractVector{<:AbstractString},
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="";
    verbose::Bool=false,
)
    if version == "latest"
        version = tzdata_latest_version()
        tzdata_hash = artifact_hash("tzdata$version", ARTIFACT_TOML)

        if tzdata_hash === nothing
            error("Latest tzdata is $version which is not present in the Artifacts.toml")
        end
    end

    artifact_dir = @artifact_str "tzdata$version"

    if !isempty(tz_source_dir)
        @info "Installing $version tzdata region data"
        regions = union!(intersect(regions, readdir(artifact_dir)), CUSTOM_REGIONS)
        for region in setdiff(regions, CUSTOM_REGIONS)
            cp(joinpath(artifact_dir, region), joinpath(tz_source_dir, region), force=true)
        end
    end
    if !isempty(compiled_dir)
        @info "Converting tz source files into TimeZone data"
        tz_source = TZSource(joinpath.(tz_source_dir, regions))
        compile(tz_source, compiled_dir)
    end

    return version
end

function build(version::AbstractString=tzdata_version())
    isdir(TZ_SOURCE_DIR) || mkpath(TZ_SOURCE_DIR)
    isdir(COMPILED_DIR) || mkpath(COMPILED_DIR)

    # Empty the compile directory in case to handle different versions not overriding all
    # files.
    for file in readdir(COMPILED_DIR)
        rm(joinpath(COMPILED_DIR, file), recursive=true)
    end

    version = build(version, REGIONS, TZ_SOURCE_DIR, COMPILED_DIR, verbose=true)

    # Store the version of the compiled tzdata
    write(ACTIVE_VERSION_FILE, version)

    return version
end
