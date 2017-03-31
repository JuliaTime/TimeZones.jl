import TimeZones: DEPS_DIR

const LATEST_FILE = joinpath(DEPS_DIR, "latest")
const LATEST_FORMAT = Base.Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")
const LATEST_DELAY = Hour(1)  # In 1996 a correction to a release was made an hour later

type Latest
    version::AbstractString
    retrieved_utc::DateTime
end

function _read(::Type{Latest}, io::IO)
    version = readline(io)
    retrieved_utc = DateTime(readline(io), LATEST_FORMAT)
    return Latest(version, retrieved_utc)
end

function _read(filename::AbstractString, ::Type{Latest})
    open(filename, "r") do io
        _read(Latest, io)
    end
end

function _write(io::IO, latest::Latest)
    write(io, latest.version)
    write(io, "\n")
    write(io, Dates.format(latest.retrieved_utc, LATEST_FORMAT))
end

const LATEST = isfile(LATEST_FILE) ? Ref{Latest}(_read(LATEST_FILE, Latest)) : Ref{Latest}()

"""
    tzdata_url(version="latest") -> AbstractString

Generates a HTTPS URL for the specified tzdata version. Typical version strings are
formatted as 4-digit year followed by a lowercase ASCII letter. Available versions can be
are listed on "ftp://ftp.iana.org/tz/releases/" which start with "tzdata".

# Examples
```julia
julia> tzdata_url("2017a")
"http://www.iana.org/time-zones/repository/releases/tzdata2017a.tar.gz"
```
"""
function tzdata_url(version::AbstractString="latest")
    # Note: We could also support FTP but the IANA server is unreliable and likely
    # to break if working from behind a firewall.
    if version == "latest"
        "https://www.iana.org/time-zones/repository/tzdata-latest.tar.gz"
    else
        "https://www.iana.org/time-zones/repository/releases/tzdata$version.tar.gz"
    end
end

"""
    tzdata_download(version="latest", dir=tempdir()) -> AbstractString

Downloads a tzdata archive from IANA using the specified `version` to the specified
directory. See `tzdata_url` for details on tzdata version strings.
"""
function tzdata_download(version::AbstractString="latest", dir::AbstractString=tempdir())
    now_utc = now(Dates.UTC)
    if version == "latest" && isdefined(LATEST, :x)
        latest = LATEST[]

        if now_utc - latest.retrieved_utc < Second(5)
            return joinpath(dir, "tzdata$(latest.version).tar.gz")
        end
    end

    url = tzdata_url(version)
    archive = Base.download(url, joinpath(dir, basename(url)))  # Overwrites the local file if any

    # HTTP 404 Not Found can result in a empty file being created
    if !isarchive(archive)
        rm(archive)
        error("Unable to download $version tzdata")
    end

    # Update the filename as if an explicit version was given
    if version == "latest"
        version = tzdata_version_archive(archive)

        archive_versioned = joinpath(dir, "tzdata$version.tar.gz")
        mv(archive, archive_versioned, remove_destination=true)
        archive = archive_versioned

        latest = Latest(version, now_utc)
        open(LATEST_FILE, "w") do io
            _write(io, latest)
        end
        LATEST[] = latest
    end

    return archive
end
