import HTTP
import JSON3
using XML

"Load the windowsZones.xml from the latest Unicode CLDR release"
function get_xml_doc()::Tuple{Node,String}
    @info "Checking for latest Unicode CLDR release..."
    response = HTTP.get("https://api.github.com/repos/unicode-org/cldr/releases/latest")
    json = JSON3.read(response.body)
    latest_cldr_version = json.tag_name  # latest release

    @info "Latest Unicode CLDR release: $latest_cldr_version"
    win_zones_url = "https://raw.githubusercontent.com/unicode-org/cldr/$latest_cldr_version/common/supplemental/windowsZones.xml"

    response = HTTP.get(win_zones_url)
    doc = parse(Node, String(response.body))
    return doc, latest_cldr_version
end

"Extract the mapping from Windows tzid to Olsen zone ID"
function create_mapping(doc::Node)::Vector{Pair{String,String}}
    timezones = doc[end][end][end]
    mapping = Pair{String,String}[]

    for node in children(timezones)
        if tag(node) == "mapZone"
            attr = attributes(node)
            # Territory "001" is the global default
            if attr["territory"] == "001"
                zone_windows = attr["other"]
                zone_olson = attr["type"]
                push!(mapping, zone_windows => zone_olson)
            end
        end
    end
    @info "Mapped $(length(mapping)) zones"
    return mapping
end

"Write the mapping to a Dict literal"
function write_code(mapping::Vector{Pair{String,String}}, latest_cldr_version::String)::Nothing
    path = normpath(@__DIR__, "../src/windows_zones.jl")
    open(path; write=true) do io
        println(io, "# This file is generated by generate_windows_zones.jl, do not edit.\n")
        println(io, "const UNICODE_CLDR_VERSION = ", repr(latest_cldr_version), '\n')
        println(io, "const WINDOWS_TRANSLATION = Dict{String, String}(")
        for zone_pair in mapping
            println(io, "    ", zone_pair, ',')
        end
        println(io, ')')
    end
    @info "Wrote $path"
    return nothing
end

"""
Generate code mapping the Windows tzid to the Olsen zone ID.
The mapping is defined by the Unicode Common Locale Data Repository (CLDR).

Details on the mapping can be found at:
https://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
"""
function main(ARGS)
    doc, latest_cldr_version = get_xml_doc()
    mapping = create_mapping(doc)
    write_code(mapping, latest_cldr_version)
end

main(ARGS)
