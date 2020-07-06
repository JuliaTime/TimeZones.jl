using Dates
using TimeZones: DEPS_DIR

const LATEST_FILE = joinpath(DEPS_DIR, "latest")
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

function write_latest(io::IO, version::AbstractString, retrieved_utc::DateTime)
    write(io, version)
    write(io, "\n")
    write(io, Dates.format(retrieved_utc, LATEST_FORMAT))
end

T = Tuple{AbstractString, DateTime}
const LATEST = isfile(LATEST_FILE) ? Ref{T}(read_latest(LATEST_FILE)) : Ref{T}()

function set_latest(version::AbstractString, retrieved_utc::DateTime)
    LATEST[] = version, retrieved_utc
    open(LATEST_FILE, "w") do io
        write_latest(io, version, retrieved_utc)
    end
end

function latest_version(now_utc::DateTime=now(Dates.UTC))
    if isassigned(LATEST)
        latest_version, latest_retrieved_utc = LATEST[]

        if now_utc - latest_retrieved_utc < LATEST_DELAY
            return latest_version
        end
    end

    return nothing
end

"""
    tzdata_url(version="latest") -> AbstractString

Generates a HTTPS URL for the specified tzdata version. Typical version strings are
formatted as 4-digit year followed by a lowercase ASCII letter. Available versions start
with "tzdata" and are listed on "https://data.iana.org/time-zones/releases/" or
"ftp://ftp.iana.org/tz/releases/".

# Examples
```julia
julia> tzdata_url("2017a")
"https://data.iana.org/time-zones/releases/tzdata2017a.tar.gz"
```
"""
function tzdata_url(version::AbstractString="latest")
    # Note: We could also support FTP but the IANA server is unreliable and likely
    # to break if working from behind a firewall.
    if version == "latest"
        "https://data.iana.org/time-zones/tzdata-latest.tar.gz"
    else
        "https://data.iana.org/time-zones/releases/tzdata$version.tar.gz"
    end
end
