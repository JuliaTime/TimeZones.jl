module WindowsTimeZoneIDs

import ...TimeZones: DEPS_DIR
using LightXML

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_URL = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"

const WINDOWS_XML_DIR = joinpath(DEPS_DIR, "local")
const WINDOWS_XML_FILE = joinpath(WINDOWS_XML_DIR, "windowsZones.xml")

isdir(WINDOWS_XML_DIR) || mkdir(WINDOWS_XML_DIR)

function compile(xml_file::AbstractString)
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

    return translation
end

const WINDOWS_TRANSLATION = if isfile(WINDOWS_XML_FILE)
    compile(WINDOWS_XML_FILE)
else
    Dict{AbstractString, AbstractString}()
end

function build(xml_file::AbstractString=WINDOWS_XML_FILE; force::Bool=false)
    fallback_xml_file = joinpath(WINDOWS_XML_DIR, "windowsZones2017a.xml")

    if !isfile(xml_file)
        if isfile(fallback_xml_file) && !force
            cp(fallback_xml_file, xml_file)
        else
            info("Downloading latest Windows to POSIX timezone ID XML")
            download(WINDOWS_ZONE_URL, xml_file)
        end
    end

    info("Compiling Windows time zone name translation")
    translation = compile(xml_file)

    # Copy contents into translation constant
    empty!(WINDOWS_TRANSLATION)
    for (k, v) in translation
        WINDOWS_TRANSLATION[k] = v
    end
end

end
