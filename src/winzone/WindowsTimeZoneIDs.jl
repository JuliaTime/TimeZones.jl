module WindowsTimeZoneIDs

using Compat: @info, findall

import ...TimeZones: DEPS_DIR
using EzXML

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_URL = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"

const WINDOWS_XML_DIR = joinpath(DEPS_DIR, "local")
const WINDOWS_XML_FILE = joinpath(WINDOWS_XML_DIR, "windowsZones.xml")

isdir(WINDOWS_XML_DIR) || mkdir(WINDOWS_XML_DIR)

function compile(xml_file::AbstractString)
    # Get the timezone conversions from the file
    doc = readxml(xml_file)

    # Territory "001" is the global default
    # Note: `findall` deprecation added in EzXML v0.8 which only works on Julia 0.7 and above
    if VERSION < v"0.7"
        map_zones = findall(doc, "//mapZone[@territory='001']")
    else
        map_zones = findall("//mapZone[@territory='001']", doc)
    end

    # TODO: Eliminate the Etc/* POSIX names here? See Windows section of `localzone`

    # Dictionary to store the windows to time zone conversions
    translation = Dict{String,String}()
    for map_zone in map_zones
        win_name = map_zone["other"]
        posix_name = map_zone["type"]
        translation[win_name] = posix_name
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
            @info "Downloading latest Windows to POSIX timezone ID XML"
            download(WINDOWS_ZONE_URL, xml_file)
        end
    end

    @info "Compiling Windows time zone name translation"
    translation = compile(xml_file)

    # Copy contents into translation constant
    empty!(WINDOWS_TRANSLATION)
    for (k, v) in translation
        WINDOWS_TRANSLATION[k] = v
    end
end

end
