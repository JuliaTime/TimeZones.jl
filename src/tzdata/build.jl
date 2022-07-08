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
# It is held within the `deps/custom_tzsource_regions` directory
const CUSTOM_REGIONS = [
    "utc",
]

const REGIONS = [STANDARD_REGIONS; LEGACY_REGIONS]


function build(
    version::AbstractString,
    regions::AbstractVector{<:AbstractString},
    tz_source_dir::Union{AbstractString,Nothing}=nothing,
    compiled_dir::Union{AbstractString,Nothing}=nothing,
)
    if version == "latest"
        version = tzdata_latest_version()
        tzdata_hash = artifact_hash("tzdata$version", ARTIFACT_TOML)

        if tzdata_hash === nothing
            error("Latest tzdata is $version which is not present in the Artifacts.toml")
        end
    end

    artifact_dir = @artifact_str "tzdata$version"

    if tz_source_dir !== nothing
        @info "Installing $version tzdata region data"
        regions = union!(intersect(regions, readdir(artifact_dir)), CUSTOM_REGIONS)
        for region in setdiff(regions, CUSTOM_REGIONS)
            cp(joinpath(artifact_dir, region), joinpath(tz_source_dir, region), force=true)
        end
        # Copy over our 'custom regions' from `deps/custom_tzsource_regions`
        custom_tz_source_dir = joinpath(dirname(dirname(@__DIR__)), "deps", "custom_tzsource_regions")
        for region in CUSTOM_REGIONS
            cp(joinpath(custom_tz_source_dir, region), joinpath(tz_source_dir, region), force=true)
        end
    end
    if compiled_dir !== nothing
        @info "Converting tz source files into TimeZone data"
        tz_source = TZSource(joinpath.(tz_source_dir, regions))
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
