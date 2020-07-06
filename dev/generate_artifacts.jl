using Pkg.Artifacts
using TimeZones.TZData: tzdata_url
using TimeZones.WindowsTimeZoneIDs: WINDOWS_ZONE_URL, WINDOWS_XML_FILE
using SHA

include(joinpath(@__DIR__, "download.jl"))
# This is the path to the Artifacts.toml we will manipulate
artifacts_toml = joinpath(dirname(@__DIR__), "Artifacts.toml")

versions = ["latest", "1996l", "1996n", "1997a", "1997b", "1997c", "1997d", "1997e", "1997f", "1997g", "1997h", "1997i",
"1997j", "1997k", "1998a", "1998b", "1998c", "1998d", "1998e", "1998h", "1998i", "1999a", "1999b", "1999c", "1999d",
"1999e", "1999f", "1999g", "1999h", "1999i", "1999j", "2000a", "2000b", "2000c", "2000d", "2000e", "2000f", "2000g",
"2000h", "2001a", "2001b", "2001c", "2001d", "2002b", "2002c", "2002d", "2003a", "2003b", "2003c", "2003d", "2003e",
"2004a", "2004b", "2004d", "2004e", "2004g", "2005a", "2005b", "2005c", "2005e", "2005f", "2005g", "2005h", "2005i",
"2005j", "2005k", "2005l", "2005m", "2005n", "2005o", "2005p", "2005q", "2005r", "2006a", "2006b", "2006c", "2006d",
"2006f", "2006g", "2006j", "2006k", "2006l", "2006m", "2006n", "2006o", "2006p", "2007a", "2007b", "2007c", "2007d",
"2007e", "2007f", "2007g", "2007h", "2007i", "2007j", "2007k", "2008a", "2008b", "2008c", "2008d", "2008e", "2008f",
"2008g", "2008h", "2008i", "2009a", "2009b", "2009c", "2009d", "2009e", "2009f", "2009g", "2009h", "2009i", "2009j",
"2009k", "2009l", "2009m", "2009n", "2009o", "2009p", "2009q", "2009r", "2009s", "2009t", "2009u", "2010a", "2010b",
"2010c", "2010d", "2010e", "2010f", "2010g", "2010h", "2010i", "2010j", "2010k", "2010l", "2010m", "2010n", "2010o",
"2011a", "2011b", "2011c", "2011d", "2011e", "2011f", "2011g", "2011h", "2011i", "2011j", "2011k", "2011l", "2011m",
"2011n", "2012a", "2012b", "2012c", "2012d", "2012e", "2012f", "2012g", "2012h", "2012i", "2012j", "2013a", "2013b",
"2013c", "2013d", "2013e", "2013f", "2013g", "2013h", "2013i", "2014a", "2014b", "2014c", "2014d", "2014e", "2014f",
"2014g", "2014h", "2014i", "2014j", "2015a", "2015b", "2015c", "2015d", "2015e", "2015f", "2015g", "2016a", "2016b",
"2016c", "2016d", "2016e", "2016f", "2016g", "2016h", "2016i", "2016j", "2017a", "2017b", "2017c", "2018a", "2018b",
"2018c", "2018d", "2018e", "2018f", "2018g", "2018h", "2018i", "2019a", "2019b", "2019c", "2020a", "93g", "94a", "94b",
"94d", "94e", "94f", "94h", "95b", "95c", "95d", "95e", "95f", "95g", "95h", "95i", "95k", "95l", "95m", "96a", "96b",
"96c", "96d", "96e", "96h", "96i", "96k"]

for version in versions
    # Query the `Artifacts.toml` file for the hash bound to the specific version
    # (returns `nothing` if no such binding exists)
    tzarchive_latest_hash = artifact_hash("tzdata_$version", artifacts_toml)

    # If the name was not bound, or the hash it was bound to does not exist, create it!
    if isnothing(tzarchive_latest_hash) || !artifact_exists(tzarchive_latest_hash)
        # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
        tzfile_hash = create_artifact() do artifact_dir
            # We create the artifact by simply downloading a few files into the new artifact directory
            @info "Downloading $version tzdata"
            tzdata_download(version, artifact_dir)
        end
        download_dir = artifact_path(tzfile_hash)
        content_sha = open(joinpath(download_dir, readdir(download_dir)[1])) do f
           bytes2hex(sha256(f))
        end

        # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
        # just overwrite with the new content-hash.  Unless the source files change, we do not expect
        # the content hash to change, so this should not cause unnecessary version control churn.
        download_data = [(tzdata_url(version), content_sha)]
        bind_artifact!(artifacts_toml, "tzdata_$version", tzfile_hash, lazy=true, download_info=download_data)
    end
end

# and now, add windows xml thingy
win_urls = ["https://raw.githubusercontent.com/JuliaTime/TimeZones.jl/v1.2.0/deps/local/windowsZones.xml",
    WINDOWS_ZONE_URL, "https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml"]
win_xml_latest_hash = artifact_hash("tzdata_windowsZones", artifacts_toml)
# If the name was not bound, or the hash it was bound to does not exist, create it!
if isnothing(win_xml_latest_hash) || !artifact_exists(win_xml_latest_hash)
    # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
    tzfile_hash = create_artifact() do artifact_dir
        # We create the artifact by simply downloading a few files into the new artifact directory
        cp(WINDOWS_XML_FILE, joinpath(artifact_dir, basename(WINDOWS_XML_FILE)))
    end

    # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
    # just overwrite with the new content-hash.  Unless the source files change, we do not expect
    # the content hash to change, so this should not cause unnecessary version control churn.
    download_data = [(url, bytes2hex(sha256(read(download(url))))) for url in win_urls]
    bind_artifact!(artifacts_toml, "tzdata_windowsZones", tzfile_hash, lazy=true, download_info=download_data)
end
