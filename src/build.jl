using .TZData: REGIONS

"""
    build(version="latest", regions=REGIONS; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter (e.g. "2016j").
Users can also specify which `regions`, or tz source files, should be compiled. Available
regions are listed under `TimeZones.REGIONS` and `TimeZones.LEGACY_REGIONS`. The `force`
flag is used to re-download tzdata archives.
"""
function build(version::AbstractString="latest", regions=REGIONS; force::Bool=false)
    TimeZones.TZData.build(version, regions)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    @info "Successfully built TimeZones"
end
