module WindowsTimeZoneIDs

using ...TimeZones: DEPS_DIR
using EzXML
if VERSION >= v"1.4"
    using Pkg.Artifacts
end

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_URL = "https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml"

const WINDOWS_XML_DIR = joinpath(DEPS_DIR, "local")
const WINDOWS_XML_FILE = joinpath(WINDOWS_XML_DIR, "windowsZones.xml")

isdir(WINDOWS_XML_DIR) || mkdir(WINDOWS_XML_DIR)

function compile(xml_file::AbstractString)
    # Get the timezone conversions from the file
    doc = readxml(xml_file)

    # Territory "001" is the global default
    map_zones = findall("//mapZone[@territory='001']", doc)

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
            if VERSION >= v"1.4"
                @info "Downloading Windows to POSIX timezone ID XML from unicode-org/cldr repo, version 37"
                xml_dir = artifact"tzdata_windowsZones"
                # no version specified in the repo so I could grep it and print it here
                cp(joinpath(xml_dir, "cldr-release-37", "common", "supplemental", "windowsZones.xml"), xml_file)
            else
                @info "Downloading latest Windows to POSIX timezone ID XML"
                download(WINDOWS_ZONE_URL, xml_file)
            end
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
