using Dates
using TimeZones: DEPS_DIR
using TimeZones.TZData: LATEST_FILE, LATEST_DELAY, latest_version, tzdata_version_dir, set_latest

if Sys.iswindows()
    if isdefined(Base, :LIBEXECDIR)
        const exe7z = joinpath(Sys.BINDIR, Base.LIBEXECDIR, "7z.exe")
    else
        const exe7z = joinpath(Sys.BINDIR, "7z.exe")
    end
end

"""
    extract(archive, directory, [files]; [verbose=false]) -> Nothing

Extracts files from a compressed tar `archive` to the specified `directory`. If `files` is
specified only the files given will be extracted. The `verbose` flag can be used to display
additional information to STDOUT.
"""
function extract(archive, directory, files=AbstractString[]; verbose::Bool=false)
    @static if Sys.iswindows()
        cmd = pipeline(`$exe7z x $archive -y -so`, `$exe7z x -si -y -ttar -o$directory $files`)
    else
        cmd = `tar xvf $archive --directory=$directory $files`
    end

    if !verbose
        cmd = pipeline(cmd, stdout=devnull, stderr=devnull)
    end

    run(cmd)
end

"""
    isarchive(path) -> Bool

Determines if the given `path` is an archive.
"""
function isarchive(path)
    @static if Sys.iswindows()
        success(`$exe7z t $path -y`)
    else
        success(`tar tf $path`)
    end
end

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
