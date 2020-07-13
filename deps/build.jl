using BinaryProvider
using TimeZones: build
using TimeZone.TZDATA: ARCHIVE_DIR,  tzdata_version
using TimeZone.WindowsTimeZoneIDs: WINDOWS_XML_DIR, WINDOWS_XML_FILE, WINDOWS_ZONE_URL

const WINDOWS_XML_DIR = joinpath(DEPS_DIR, "local")
const WINDOWS_XML_FILE = joinpath(WINDOWS_XML_DIR, "windowsZones.xml")
const WINDOWS_DOWNLOAD_LINK = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"
const WINDOWS_DOWNLOAD_LINK_FALLBACK = WINDOWS_ZONE_URL
const TZDATA_FALLBACK_URL_LATEST = "https://data.iana.org/time-zones/tzdata-latest.tar.gz"
const TZDATA_RELEASES_URLS = Dict(

)

function download_with_fallback(url, destination, fallback_url)
    tempfile = mktemp()
    try
        BinaryProvider.download(url, tempfile)
    catch ex
        @warn "Failed to download windowsZones.xml" ex
        try
            BinaryProvider.download(fallback_url, tempfile)
        catch ex
            @error "Failed to download from fallback url" ex
            return
        end
    end
    mv(tempfile, destination, force=true)
end

@static if Sys.iswindows()
    if !isfile(WINDOWS_XML_FILE)
        download_with_fallback(WINDOWS_DOWNLOAD_LINK, WINDOWS_XML_FILE, WINDOWS_DOWNLOAD_LINK_FALLBACK)
    end
end

#=
if !isarchive(archive)
    rm(archive)
    error("Unable to download $version tzdata")
end
=#
version =  tzdata_version()
download_url = TZDATA_RELEASES_URLS[version]
download_with_fallback(download_URL, joinpath(ARCHIVE_DIR, "tzdata$(version).tar.gz"), TZDATA_FALLBACK_URL_LATEST)
if !isarchive(archive)
    rm(archive)
    error("Unable to download $version tzdata")
end
build()
