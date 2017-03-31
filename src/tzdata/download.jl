import TimeZones: DEPS_DIR

const LATEST_FILE = joinpath(DEPS_DIR, "latest")
const LATEST_FORMAT = Base.Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")
const LATEST_DELAY = Hour(1)  # In 1996 a correction to a release was made an hour later

function read_latest(io::IO)
    version = readline(io)
    retrieved_utc = DateTime(readline(io), LATEST_FORMAT)
    return version, retrieved_utc
end

function read_latest(filename::AbstractString)
    open(filename, "r") do io
        read_latest(io)
    end
end

function write_latest(io::IO, version::AbstractString, retrieved_utc::DateTime)
    write(io, version)
    write(io, "\n")
    write(io, Dates.format(retrieved_utc, LATEST_FORMAT))
end

T = Tuple{AbstractString, DateTime}
const LATEST = isfile(LATEST_FILE) ? Ref{T}(read_latest(LATEST_FILE)) : Ref{T}()

is_latest_defined() = isdefined(LATEST, :x)
get_latest() = LATEST[]

function set_latest(version::AbstractString, retrieved_utc::DateTime)
    LATEST[] = version, retrieved_utc
    open(LATEST_FILE, "w") do io
        write_latest(io, version, retrieved_utc)
    end
end

function latest_version(now_utc::DateTime=now(Dates.UTC))
    if is_latest_defined()
        latest_version, latest_retrieved_utc = get_latest()

        if now_utc - latest_retrieved_utc < LATEST_DELAY
            return Nullable{AbstractString}(latest_version)
        end
    end

    return Nullable{AbstractString}()
end

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
    if version == "latest"
        v = latest_version(now_utc)
        if !isnull(v)
            return joinpath(dir, "tzdata$(unsafe_get(v)).tar.gz")
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

        set_latest(version, now_utc)
    end

    return archive
end
