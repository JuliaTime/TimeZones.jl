"""
    build(version="latest"; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter (e.g. "2016j").
The `force` flag is used to re-download tzdata archives.
"""
function build(version::AbstractString="latest"; force::Bool=false)
    TimeZones.TZData.build(version)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    # Reset cached information
    empty!(TIME_ZONE_CACHE)

    @info "Successfully built TimeZones"
end
