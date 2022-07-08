using TimeZones.TZData: DEFAULT_TZDATA_VERSION, tzdata_version

"""
    build(version="$DEFAULT_TZDATA_VERSION"; force=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter
(e.g. "$DEFAULT_TZDATA_VERSION"). The `force` flag is used to re-download tzdata archives.
"""
function build(version::AbstractString=tzdata_version(); force::Bool=false)
    tz_source_dir = _tz_source_dir(version)
    compiled_dir = _compiled_dir(version)

    isdir(tz_source_dir) && rm(tz_source_dir, recursive=true)
    isdir(compiled_dir) && rm(compiled_dir, recursive=true)
    mkpath(tz_source_dir)
    mkpath(compiled_dir)

    TimeZones.TZData.build(version, TZData.REGIONS, tz_source_dir, compiled_dir)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    # Set the compiled directory to the new location
    COMPILED_DIR[] = compiled_dir

    # Reset cached information
    _reset_tz_cache()

    @info "Successfully built TimeZones"
end
