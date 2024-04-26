import HTTP
import JSON3
using XML

"Determine the latest Unicode CLDR release"
function unicode_cldr_latest_release()::String
    response = HTTP.get("https://api.github.com/repos/unicode-org/cldr/releases/latest")
    json = JSON3.read(response.body)
    return json.tag_name
end

"Download the `windowsZones.xml` from the Unicode CLDR release"
function download_windows_zones_xml(unicode_cldr_release::String)::String
    win_zones_url = "https://raw.githubusercontent.com/unicode-org/cldr/$unicode_cldr_release/common/supplemental/windowsZones.xml"
    response = HTTP.get(win_zones_url)
    return String(response.body)
end

"Extract the mapping from Windows tzid to Olsen zone ID"
function create_mapping(windows_zone_xml::AbstractString)::Vector{Pair{String,String}}
    doc = parse(Node, windows_zone_xml)
    supplemental_data = only(filter(node -> tag(node) == "supplementalData", children(doc)))
    windows_zones = only(filter(node -> tag(node) == "windowsZones", children(supplemental_data)))
    timezones = only(filter(node -> tag(node) == "mapTimezones", children(windows_zones)))
    mapping = Pair{String,String}[]

    for node in children(timezones)
        if tag(node) == "mapZone"
            attr = attributes(node)
            # Territory "001" is the global default
            if attr["territory"] == "001"
                windows_zone_name = attr["other"]
                tzdata_name = attr["type"]
                push!(mapping, windows_zone_name => tzdata_name)
            end
        end
    end
    return mapping
end

"Write the mapping to a Dict literal"
function generate_code(io::IO, mapping::Vector{Pair{String,String}}, latest_cldr_version::String)::Nothing
    path = normpath(@__DIR__, "../src/windows_zones.jl")
    open(path; write=true) do io
        println(io, "# This file is generated by `dev/generate_windows_zones.jl`, do not edit.\n")
        println(io, "const UNICODE_CLDR_VERSION = ", repr(latest_cldr_version), '\n')
        println(io, "const WINDOWS_TRANSLATION = Dict{String, String}(")
        for zone_pair in mapping
            println(io, "    ", repr(zone_pair), ',')
        end
        println(io, ')')
    end
    return nothing
end

"""
Generate code mapping the Windows tzid to the Olsen zone ID.
The mapping is defined by the Unicode Common Locale Data Repository (CLDR).

Details on the mapping can be found at:
https://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
"""
function main(ARGS)
    latest_cldr_version = unicode_cldr_latest_release()
    @info "Latest Unicode CLDR release: $latest_cldr_version"

    xml_str = download_windows_zones_xml(latest_cldr_version)
    mapping = create_mapping(xml_str)
    @info "Mapped $(length(mapping)) zones"

    open(joinpath(@__DIR__, "..", "src", "windows_zones.jl"), "w") do io
        generate_code(io, mapping, latest_cldr_version)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
