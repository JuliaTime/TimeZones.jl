using TimeZones.TZData: DEFAULT_TZDATA_VERSION, tzdata_version

"""
    build(version="$DEFAULT_TZDATA_VERSION"; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter
(e.g. "$DEFAULT_TZDATA_VERSION"). The `force` flag is used to re-download tzdata archives.

!!! warning
    This function is *not* thread-safe and meant primarily for experimentation.
"""
function build(version::AbstractString=tzdata_version(); force::Bool=false)
    built = TimeZones.TZData.build(version, returned=:namedtuple)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    # Set the compiled directory to the new location
    _COMPILED_DIR[] = built.compiled_dir

    # Reset cached information
    _prefetch_tz_cache()

    @info "Successfully built TimeZones"
end
