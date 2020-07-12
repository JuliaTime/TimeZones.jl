using Pkg.Artifacts
using TimeZones.TZData: tzdata_url
#using TimeZones.WindowsTimeZoneIDs: WINDOWS_ZONE_URL, WINDOWS_XML_FILE
using SHA
using Pkg.BinaryPlatforms
using TimeZones.TZData: extract, tzdata_download

# This is the path to the Artifacts.toml we will manipulate
artifacts_toml = joinpath(dirname(@__DIR__), "Artifacts.toml")

const VERSIONS = let
    file = download("https://data.iana.org/time-zones/releases/")
    html = read(file, String)
    rm(file)
    [m[:version] for m in eachmatch(r"href=\"tzdata(?<version>(?:\d{2}){1,2}[a-z]?).tar.gz\"", html)]
end

for version in VERSIONS
    # Query the `Artifacts.toml` file for the hash bound to the specific version
    # (returns `nothing` if no such binding exists)
    tzarchive_latest_hash = artifact_hash("tzdata_$version", artifacts_toml)

    # If the name was not bound, or the hash it was bound to does not exist, create it!
    if isnothing(tzarchive_latest_hash) || !artifact_exists(tzarchive_latest_hash)
        # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
        tzfile_hash = create_artifact() do artifact_dir
            # We create the artifact by simply downloading a few files into the new artifact directory
            @info "Downloading $version tzdata"
            archive_name = tzdata_download(version, artifact_dir)
            extract(archive_name, artifact_dir)
            rm(archive_name)
        end
        download_dir = artifact_path(tzfile_hash)
        content_sha = open(tzdata_download(version)) do f
           bytes2hex(sha256(f))
        end

        # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
        # just overwrite with the new content-hash.  Unless the source files change, we do not expect
        # the content hash to change, so this should not cause unnecessary version control churn.
        download_data = [(tzdata_url(version), content_sha)]
        #bind_artifact!(artifacts_toml, "tzdata_$version", tzfile_hash, lazy=true, download_info=download_data, platform=platform_key_abi())
        bind_artifact!(artifacts_toml, "tzdata_$version", tzfile_hash, lazy=true, download_info=download_data)
    end
end

# and now, add windows xml thingy, but as the whole tarball of github release
win_xml_archive_url = "https://github.com/unicode-org/cldr/archive/release-37.tar.gz"
win_xml_latest_hash = artifact_hash("tzdata_windowsZones", artifacts_toml)
# If the name was not bound, or the hash it was bound to does not exist, create it!
if isnothing(win_xml_latest_hash) || !artifact_exists(win_xml_latest_hash)
    # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
    tzfile_hash = create_artifact() do artifact_dir
        # We create the artifact by simply downloading a few files into the new artifact directory
        archive_name = download(win_xml_archive_url, joinpath(artifact_dir, basename(win_xml_archive_url)))
        # @info "Downloading to $artifact_dir" a
        # archive_name = tzdata_download(version, artifact_dir)
        extract(archive_name, artifact_dir)
        rm(archive_name)
    end
    download_dir = artifact_path(tzfile_hash)
    content_sha = open(download(win_xml_archive_url)) do f
       bytes2hex(sha256(f))
    end

    # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
    # just overwrite with the new content-hash.  Unless the source files change, we do not expect
    # the content hash to change, so this should not cause unnecessary version control churn.
    download_data = [(win_xml_archive_url, content_sha)]
    bind_artifact!(artifacts_toml, "tzdata_windowsZones", tzfile_hash, lazy=true, download_info=download_data)
end

# using Pkg.BinaryPlatforms
# platform_key_abi()
# typeof(platform_key_abi())
# typeof(platform_key_abi())
