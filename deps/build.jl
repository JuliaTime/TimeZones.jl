import TimeZones: TZDATA_DIR, COMPILED_DIR
import TimeZones.Olson: compile

@windows_only import TimeZones: TRANSLATION_FILE
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

# TODO: Downloading fails regularly. Implement a retry system or file alternative
# sources.
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
    translation_dir = dirname(TRANSLATION_FILE)
    isdir(translation_dir) || mkdir(translation_dir)

    # Windows is weird and uses its own timezone
    info("Downloading Windows to TZ name XML")

    # Generate the mapping between MS Windows timezone names and
    # tzdata/Olsen timezone names, by retrieving a file.
    xml_source = "http://unicode.org/cldr/data/common/supplemental/windowsZones.xml"
    xml_file = joinpath(translation_dir, "windowsZones.xml")
    # Download the xml file from source
    download(xml_source, xml_file)

    info("Pre-processing Windows translation")

    # Get the timezone conversions from the file
    xdoc = parse_file(xml_file)
    xroot = root(xdoc)
    windowsZones = find_element(xroot, "windowsZones")
    mapTimezones = find_element(windowsZones, "mapTimezones")
    # Every mapZone is a conversion
    mapZones = get_elements_by_tagname(mapTimezones, "mapZone")

    # Dictionary to store the windows to timezone conversions
    win_tz = Dict{AbstractString,AbstractString}()

    # Add conversions to the dictionary
    for mapzone in mapZones
        # territory "001" is the global default
        # http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
        if attribute(mapzone, "territory") == "001"
            windowszone = attribute(mapzone, "other")
            utczone = attribute(mapzone, "type")
            win_tz[windowszone] = utczone
        end
    end

    # Save the dictionary
    open(TRANSLATION_FILE, "w") do fp
        serialize(fp, win_tz)
    end
end

info("Successfully processed TimeZone data")
