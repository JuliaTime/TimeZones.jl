import TimeZones: TZDATA_DIR, COMPILED_DIR
import TimeZones.Olson: compile

@windows_only import TimeZones: WIN_TRANSLATION_FILE
@windows_only using LightXML

# Various sources from which the latest compressed TZ data can be retrieved.
# Note: HTTP sources are preferable as they tend to work behind firewalls.
const URLS = (
    "https://www.iana.org/time-zones/repository/tzdata-latest.tar.gz",
    "ftp://ftp.iana.org/tz/tzdata-latest.tar.gz",  # Unreliable source
)

# See "ftp://ftp.iana.org/tz/data/Makefile" PRIMARY_YDATA for listing of
# regions to include. YDATA includes historical zones which we'll ignore.
const REGIONS = (
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica",
    # "pacificnew", "etcetera", "backward",  # Historical zones
)

isdir(TZDATA_DIR) || mkdir(TZDATA_DIR)
isdir(COMPILED_DIR) || mkdir(COMPILED_DIR)

info("Downloading TZ data")
archive = ""
for url in URLS
    try
        archive = download(url)
        break
    catch
        warn("Failed to download TZ data from: $url")
    end
end
isfile(archive) || error("Unable to download TZ data")

info("Extracting TZ data")
@unix_only function extract(archive, directory, files)
    run(`tar xvf $archive --directory=$directory $files`)
end
@windows_only function extract(archive, directory, files)
    run(pipeline(`7z x $archive -y -so`, `7z x -si -y -ttar -o$directory $files`))
end

extract(archive, TZDATA_DIR, REGIONS)
rm(archive)


info("Pre-processing TimeZone data")
for file in readdir(COMPILED_DIR)
    rm(joinpath(COMPILED_DIR, file), recursive=true)
end
compile(TZDATA_DIR, COMPILED_DIR)

@windows_only begin
    translation_dir = dirname(WIN_TRANSLATION_FILE)
    isdir(translation_dir) || mkdir(translation_dir)

    info("Downloading Windows to POSIX timezone name XML")

    # Retrieve a mapping of Windows timezone names to Olson timezone names.
    # Details on the contents of this file can be found at:
    # http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
    xml_source = "http://unicode.org/cldr/data/common/supplemental/windowsZones.xml"
    xml_file = joinpath(translation_dir, "windowsZones.xml")
    download(xml_source, xml_file)

    info("Pre-processing Windows translation")

    # Get the timezone conversions from the file
    xdoc = parse_file(xml_file)
    xroot = root(xdoc)
    windows_zones = find_element(xroot, "windowsZones")
    map_timezones = find_element(windows_zones, "mapTimezones")
    map_zones = get_elements_by_tagname(map_timezones, "mapZone")

    # TODO: Eliminate the Etc/* POSIX names here? See @windows_only localzone

    # Dictionary to store the windows to timezone conversions
    translation = Dict{AbstractString,AbstractString}()
    for map_zone in map_zones
        # Territory "001" is the global default
        if attribute(map_zone, "territory") == "001"
            win_name = attribute(map_zone, "other")
            posix_name = attribute(map_zone, "type")
            translation[win_name] = posix_name
        end
    end

    open(WIN_TRANSLATION_FILE, "w") do fp
        serialize(fp, translation)
    end
end

info("Successfully processed TimeZone data")
