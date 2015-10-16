import TimeZones: TZDATA_DIR, COMPILED_DIR
import TimeZones.Olson: compile

@windows_only import TimeZones: WIN_TRANSLATION_FILE
@windows_only using LightXML

# See "ftp://ftp.iana.org/tz/data/Makefile" PRIMARY_YDATA for listing of
# regions to include. YDATA includes historical zones which we'll ignore.
const REGIONS = (
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica",
    # "pacificnew", "etcetera", "backward",  # Historical zones
)

isdir(TZDATA_DIR) || mkdir(TZDATA_DIR)
isdir(COMPILED_DIR) || mkdir(COMPILED_DIR)

# TODO: Downloading from the IANA source fails regularly. We should attempt to find
# alternative sources.
info("Downloading TZ data")
@sync for region in REGIONS
    @async begin
        remote_file = "ftp://ftp.iana.org/tz/data/" * region
        region_file = joinpath(TZDATA_DIR, region)
        remaining = 3

        while remaining > 0
            try
                # Note the destination file will be overwritten upon success.
                download(remote_file, region_file)
                remaining = 0
            catch e
                if isa(e, ErrorException)
                    if remaining > 0
                        remaining -= 1
                    elseif isfile(region_file)
                        warn("Falling back to old region file $region. Unable to download: $remote_file")
                    else
                        error("Missing region file $region. Unable to download: $remote_file")
                    end
                else
                    rethrow()
                end
            end
        end
    end
end


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
