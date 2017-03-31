import TimeZones: ARCHIVE_DIR, TZ_SOURCE_DIR, COMPILED_DIR

# The default tzdata region files we care about. See "ftp://ftp.iana.org/tz/data/Makefile"
# PRIMARY_YDATA for listing of regions to include. YDATA includes historical zones which
# we'll ignore.
const REGIONS = (
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica",
    # "pacificnew", "etcetera", "backward",  # Historical zones
)

function build(
    version::AbstractString,
    regions,
    archive_dir::AbstractString,
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="";
    verbose::Bool=true,
)
    # Avoids spaming remote servers requesting the latest version
    if version == "latest"
        version = get(latest_version(), "latest")

        if version != "latest"
            info("Latest tzdata is $version")
        end
    end

    archive = joinpath(archive_dir, "tzdata$version.tar.gz")

    # Avoid downloading a tzdata archive if we already have a local copy
    if version == "latest" || !isfile(archive)
        info("Downloading $version tzdata")
        archive = tzdata_download(version, archive_dir)

        if version == "latest"
            m = match(TZDATA_VERSION_REGEX, basename(archive))
            if m !== nothing
                abs_release = m.match
                info("Latest tzdata is $abs_release")
            end
        end
    end

    if !isempty(tz_source_dir)
        info("Extracting tzdata archive")
        extract(archive, tz_source_dir, regions, verbose=verbose)
    end

    if !isempty(compiled_dir)
        info("Converting tz source files into TimeZone data")
        compile(tz_source_dir, compiled_dir)
    end
end

function build(version::AbstractString="latest", regions=REGIONS)
    isdir(ARCHIVE_DIR) || mkdir(ARCHIVE_DIR)
    isdir(TZ_SOURCE_DIR) || mkdir(TZ_SOURCE_DIR)
    isdir(COMPILED_DIR) || mkdir(COMPILED_DIR)

    # Empty the compile directory in case to handle different versions not overriding all
    # files.
    for file in readdir(COMPILED_DIR)
        rm(joinpath(COMPILED_DIR, file), recursive=true)
    end

    build(version, regions, ARCHIVE_DIR, TZ_SOURCE_DIR, COMPILED_DIR)
end
