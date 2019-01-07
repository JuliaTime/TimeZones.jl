"""
    build(version="latest"; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter (e.g. "2016j").
The `force` flag is used to re-download tzdata archives.
"""
function build(version::AbstractString="latest"; force::Bool=false)
    version, tz_category = TimeZones.TZData.build(version)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    # Reset cached information
    empty!(TIME_ZONE_CACHE)
    empty!(TIME_ZONE_NAMES)
    for (class, tz_names) in tz_category
        TIME_ZONE_NAMES[class] = sort!(tz_names)
    end

    @info "Successfully built TimeZones"
end
