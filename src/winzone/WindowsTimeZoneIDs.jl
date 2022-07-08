module WindowsTimeZoneIDs

using LazyArtifacts
using ...TimeZones: scratch_dir

const UNICODE_CLDR_VERSION = "release-40"

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_FILE = joinpath("cldr-$UNICODE_CLDR_VERSION", "common", "supplemental", "windowsZones.xml")
windows_xml_file_path() = joinpath(scratch_dir("local"), "windowsZones.xml")

const WINDOWS_TRANSLATION = Dict{String, String}()

function __init__()
    xml_file_path = windows_xml_file_path()
    if isfile(xml_file_path)
        copy!(WINDOWS_TRANSLATION, compile(xml_file_path))
    end
end

function compile(xml_file::AbstractString)
    translation = Dict{String,String}()

    # Get the timezone conversions from the file
    #
    # Note: Since the XML file is simplistic enough that we can parse what we need via a
    # regex we can avoid having an XML package dependency. Additionally, since this XML file
    # is included as part of the this package we can correct any parsing issues before a
    # TimeZones.jl release occurs.
    for line in readlines(xml_file)
        # Territory "001" is the global default
        occursin("territory=\"001\"", line) || continue
        win_name = match(r"other=\"(.*?)\"", line)[1]
        posix_name = match(r"type=\"(.*?)\"", line)[1]
        translation[win_name] = posix_name
    end

    return translation
end

function build(xml_file::AbstractString=windows_xml_file_path(); force::Bool=false)
    if !isfile(xml_file) || force
        @info "Downloading Windows to POSIX timezone ID XML version: $UNICODE_CLDR_VERSION"
        artifact_dir = @artifact_str "unicode-cldr-$UNICODE_CLDR_VERSION"
        cp(joinpath(artifact_dir, WINDOWS_ZONE_FILE), xml_file, force=true)
    end

    @info "Compiling Windows time zone name translation"
    copy!(WINDOWS_TRANSLATION, compile(xml_file))
end

end
