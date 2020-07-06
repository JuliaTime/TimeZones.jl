using Dates
using TimeZones: DEPS_DIR
using TimeZones.TZData: LATEST_FILE, LATEST_DELAY, latest_version, tzdata_version_dir, set_latest, isarchive, extract

"""
    tzdata_download(version="latest", dir=tempdir()) -> AbstractString

Downloads a tzdata archive from IANA using the specified `version` to the specified
directory. See `tzdata_url` for details on tzdata version strings.
Not used during the build, but used when creating the `Artifacts.toml` file.
"""
function tzdata_download(version::AbstractString="latest", dir::AbstractString=tempdir())
    now_utc = now(Dates.UTC)
    if version == "latest"
        v = latest_version(now_utc)
        if v !== nothing
            archive = joinpath(dir, "tzdata$(v).tar.gz")
            isfile(archive) && return archive
        end
    end

    url = tzdata_url(version)
    archive = Base.download(url, joinpath(dir, basename(url)))  # Overwrites the local file if any

    # Note: An "HTTP 404 Not Found" may result in the 404 page being downloaded. Also,
    # catches issues with corrupt archives
    if !isarchive(archive)
        rm(archive)
        error("Unable to download $version tzdata")
    end

    # Rename the file to have an explicit version
    if version == "latest"
        mktempdir() do temp_dir
            extract(archive, temp_dir)
            version = tzdata_version_dir(temp_dir)
        end

        archive_versioned = joinpath(dir, "tzdata$version.tar.gz")
        mv(archive, archive_versioned, force=true)
        archive = archive_versioned

        set_latest(version, now_utc)
    end

    return archive
end
