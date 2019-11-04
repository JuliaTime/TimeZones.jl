using TimeZones.TZData: DEFAULT_TZDATA_VERSION, tzdata_version

"""
    build(version="$DEFAULT_TZDATA_VERSION"; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter
(e.g. "$DEFAULT_TZDATA_VERSION"). The `force` flag is used to re-download tzdata archives.
"""
function build(version::AbstractString=tzdata_version(); force::Bool=false)
    TimeZones.TZData.build(version)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    # Reset cached information
    empty!(TIME_ZONE_CACHE)

    @info "Successfully built TimeZones"
end
