using ...TimeZones: Class
if VERSION >= v"1.3"
    # Artifacts introduced in Pkg v1.3
    # Using Pkg instead of using LazyArtifacts is deprecated on 1.6.0-beta1.15 and 1.7.0-DEV.302
    # LazyArtifacts.jl available for v1.3 and up
    using LazyArtifacts
end

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
    archive_dir::AbstractString,
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="";
    verbose::Bool=false,
)
    @static if VERSION >= v"1.3"
        # Determine the current "latest" version but limit how often we check with remote
        # servers.
        if version == "latest"
            latest_version = latest_cached()

            # Retrieve the current latest version the cached latest has expired
            if latest_version === nothing
                latest_version = last(tzdata_versions())
                tzdata_hash = artifact_hash("tzdata$latest_version", ARTIFACT_TOML)

                if tzdata_hash === nothing
                    error("Latest tzdata is $latest_version which is not present in the Artifacts.toml")
                end

                set_latest_cached(latest_version)
            end

            version = latest_version
        end

        artifact_dir = @artifact_str "tzdata$version"

        if !isempty(tz_source_dir)
            @info "Installing $version tzdata region data"
            regions = union!(intersect(regions, readdir(artifact_dir)), CUSTOM_REGIONS)
            for region in setdiff(regions, CUSTOM_REGIONS)
                cp(joinpath(artifact_dir, region), joinpath(tz_source_dir, region), force=true)
            end
        end
    else
        # Avoids spamming remote servers requesting the latest version
        if version == "latest"
            v = latest_cached()

            if v !== nothing
                version = v
                @info "Latest tzdata is $version"
            end
        end

        archive = joinpath(archive_dir, "tzdata$version.tar.gz")

        # Avoid downloading a tzdata archive if we already have a local copy
        if version == "latest" || !isfile(archive)
            @info "Downloading $version tzdata"
            archive = tzdata_download(version, archive_dir)

            if version == "latest"
                m = match(TZDATA_VERSION_REGEX, basename(archive))
                if m !== nothing
                    version = m.match
                    @info "Latest tzdata is $version"
                end
            end
        end

        if !isempty(tz_source_dir)
            @info "Extracting $version tzdata archive"
            regions = union!(intersect(regions, readarchive(archive)), CUSTOM_REGIONS)
            extract(archive, tz_source_dir, setdiff(regions, CUSTOM_REGIONS), verbose=verbose)
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
    isdir(ARCHIVE_DIR) || mkpath(ARCHIVE_DIR)
    isdir(TZ_SOURCE_DIR) || mkpath(TZ_SOURCE_DIR)
    isdir(COMPILED_DIR) || mkpath(COMPILED_DIR)

    # Empty the compile directory in case to handle different versions not overriding all
    # files.
    for file in readdir(COMPILED_DIR)
        rm(joinpath(COMPILED_DIR, file), recursive=true)
    end

    version = build(
        version, REGIONS, ARCHIVE_DIR, TZ_SOURCE_DIR, COMPILED_DIR, verbose=true,
    )

    # Store the version of the compiled tzdata
    write(ACTIVE_VERSION_FILE, version)

    return version
end
