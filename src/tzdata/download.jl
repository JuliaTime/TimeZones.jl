using Downloads: download

const LATEST_FORMAT = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS")
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

function write_latest(io::IO, version::AbstractString, retrieved_utc::DateTime=now(Dates.UTC))
    write(io, version)
    write(io, "\n")
    write(io, Dates.format(retrieved_utc, LATEST_FORMAT))
end

function set_latest_cached(version::AbstractString, retrieved_utc::DateTime=now(Dates.UTC))
    _LATEST[] = version, retrieved_utc
    open(_LATEST_FILE_PATH[], "w") do io
        write_latest(io, version, retrieved_utc)
    end
end

function latest_cached(now_utc::DateTime=now(Dates.UTC))
    if isassigned(_LATEST)
        latest_version, latest_retrieved_utc = _LATEST[]

        if now_utc - latest_retrieved_utc < LATEST_DELAY
            return latest_version
        end
    end

    return nothing
end

"""
    tzdata_versions() -> Vector{String}

Retrieves all of the currently available tzdata versions from IANA. The version list is
ordered from earliest to latest.

# Examples
```julia
julia> last(tzdata_versions())  # Current latest available tzdata version
"2020a"
```
"""
function tzdata_versions()
    io = download("https://data.iana.org/time-zones/releases/", IOBuffer())
    html = String(take!(io))

    versions = [
        m[:version]
        for m in eachmatch(r"href=\"tzdata(?<version>(?:\d{2}){1,2}[a-z]?).tar.gz\"", html)
    ]

    # Correctly order releases which include 2-digit years (e.g. "96")
    sort!(versions, by=v -> length(v) < 5 ? "19$v" : v)

    return versions
end

"""
    tzdata_latest_version() -> String

Determine the latest version of tzdata available while limiting how often we check with
remote servers.
"""
function tzdata_latest_version()
    latest_version = latest_cached()

    # Retrieve the current latest version the cached latest has expired
    if latest_version === nothing
        latest_version = last(tzdata_versions())
        set_latest_cached(latest_version)
    end

    return latest_version
end

"""
    tzdata_url(version::AbstractVersion) -> AbstractString

Generate a HTTPS URL for the specified tzdata version. Typical version strings are
formatted as 4-digit year followed by a lowercase ASCII letter. Available versions can be
listed with [`tzdata_versions`](@ref) or by viewing the contents of
"https://data.iana.org/time-zones/releases/" and looking at the files starting with
"tzdata".

# Examples
```julia
julia> tzdata_url("2017a")
"https://data.iana.org/time-zones/releases/tzdata2017a.tar.gz"
```
"""
function tzdata_url(version::AbstractString)
    # Note: IANA also provides tzdata via an FTP server at "ftp://ftp.iana.org/tz/releases/"
    # but this service is unreliable and likely to break if accessing the service from
    # behind a firewall.
    return "https://data.iana.org/time-zones/releases/tzdata$version.tar.gz"
end
