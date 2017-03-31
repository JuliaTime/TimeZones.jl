module WindowsTimeZoneIDs

import ...TimeZones: DEPS_DIR
using LightXML

const WIN_TRANSLATION_FILE = joinpath(DEPS_DIR, "windows_to_posix")

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONES_URL = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"

translation_dir = dirname(WIN_TRANSLATION_FILE)
isdir(translation_dir) || mkdir(translation_dir)

function compile(xml_file::AbstractString, translation_file::AbstractString)
    # Get the timezone conversions from the file
    xdoc = parse_file(xml_file)
    xroot = root(xdoc)
    windows_zones = find_element(xroot, "windowsZones")
    map_timezones = find_element(windows_zones, "mapTimezones")
    map_zones = get_elements_by_tagname(map_timezones, "mapZone")

    # TODO: Eliminate the Etc/* POSIX names here? See Windows section of `localzone`

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

    open(translation_file, "w") do fp
        serialize(fp, translation)
    end
end


function build(; force::Bool=false)
    clean = false
    xml_file = joinpath(dirname(WIN_TRANSLATION_FILE), "windowsZones.xml")

    if !isfile(xml_file) || force
        info("Downloading latest Windows to POSIX timezone ID XML")
        xml_file = download(WINDOWS_ZONES_URL)
        clean = true
    end

    info("Compiling Windows time zone name translation")
    compile(xml_file, WIN_TRANSLATION_FILE)

    # Remove temporary XML file
    if clean
        rm(xml_file)
    end
end

end
