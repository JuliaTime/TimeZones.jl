module WindowsTimeZoneIDs

import ...TimeZones: DEPS_DIR
using LightXML

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_URL = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"

const WINDOWS_TRANSLATION_FILE = joinpath(DEPS_DIR, "windows_to_posix")
const WINDOWS_TRANSLATION = Dict{AbstractString,AbstractString}()

translation_dir = dirname(WINDOWS_TRANSLATION_FILE)
isdir(translation_dir) || mkdir(translation_dir)

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

function compile(xml_file::AbstractString, translation_file::AbstractString)
    open(translation_file, "w") do fp
        serialize(fp, compile(xml_file))
    end
end

function build(
    xml_dir::AbstractString=joinpath(DEPS_DIR, "local"),
    translation_file::AbstractString=WINDOWS_TRANSLATION_FILE;
    force::Bool=false,
)
    clean = false
    xml_file = joinpath(xml_dir, "windowsZones2017a.xml")

    if !isfile(xml_file) || force
        info("Downloading latest Windows to POSIX timezone ID XML")
        xml_file = download(WINDOWS_ZONE_URL, joinpath(xml_dir, "windowsZones.xml"))
        clean = true
    end

    info("Compiling Windows time zone name translation")
    compile(xml_file, translation_file)

    # Remove temporary XML file
    if clean
        rm(xml_file)
    end
end

function build(; force::Bool=false)
    build(force=force)
    empty!(WINDOWS_TRANSLATION)
end

function load_translation(translation_file::AbstractString)
    return open(translation_file, "r") do fp
        deserialize(fp)
    end
end

function get_windows_translation()
    if isempty(WINDOWS_TRANSLATION)
        if !isfile(WINDOWS_TRANSLATION_FILE)
            error(
                "Missing Windows to POSIX time zone translation file. ",
                "Try running Pkg.build(\"TimeZones\").",
            )
        end

        translation = load_translation(WINDOWS_TRANSLATION_FILE)

        # Copy contents into translation constant
        for (k, v) in translation
            WINDOWS_TRANSLATION[k] = v
        end
    end

    return WINDOWS_TRANSLATION
end

end
