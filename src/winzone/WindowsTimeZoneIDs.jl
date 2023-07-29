module WindowsTimeZoneIDs

using Artifacts: @artifact_str
using ...TimeZones: _scratch_dir

const UNICODE_CLDR_VERSION = "release-43-1"

# A mapping of Windows timezone names to Olson timezone names.
# Details on the contents of this file can be found at:
# http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
const WINDOWS_ZONE_FILE = joinpath("cldr-$UNICODE_CLDR_VERSION", "common", "supplemental", "windowsZones.xml")
const _WINDOWS_XML_FILE_PATH = Ref{String}()

const WINDOWS_TRANSLATION = Dict{String, String}()

function __init__()
    _WINDOWS_XML_FILE_PATH[] = joinpath(_scratch_dir(), "local", "windowsZones.xml")
    if isfile(_WINDOWS_XML_FILE_PATH[])
        copy!(WINDOWS_TRANSLATION, compile(_WINDOWS_XML_FILE_PATH[]))
    else
        build()
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

function build(xml_file::AbstractString; force::Bool=false)
    if !isfile(xml_file) || force
        @info "Downloading Windows to POSIX timezone ID XML version: $UNICODE_CLDR_VERSION"
        artifact_dir = @artifact_str "unicode-cldr-$UNICODE_CLDR_VERSION"
        cp(joinpath(artifact_dir, WINDOWS_ZONE_FILE), xml_file, force=true)
    end

    @info "Compiling Windows time zone name translation"
    copy!(WINDOWS_TRANSLATION, compile(xml_file))
end

function build(; kwargs...)
    # Note: Directory creation during package initialization can cause failures when using
    # PackageCompiler.jl: https://github.com/JuliaTime/TimeZones.jl/issues/371
    windows_xml_dir = dirname(_WINDOWS_XML_FILE_PATH[])
    isdir(windows_xml_dir) || mkdir(windows_xml_dir)
    return build(_WINDOWS_XML_FILE_PATH[]; kwargs...)
end

end
