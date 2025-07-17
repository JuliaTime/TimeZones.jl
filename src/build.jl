"""
    build(version::AbstractString; force::Bool=false) -> Nothing

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter
(e.g. "$(TZJData.TZDATA_VERSION)"). The `force` flag is used to re-download tzdata archives.

!!! warning
    This function is *not* thread-safe and meant primarily for experimentation.
"""
function build(version::AbstractString; force::Bool=false)
    compiled_dir = TimeZones.TZData.build(version, _scratch_dir())

    # Set the compiled directory to the new location
    _COMPILED_DIR[] = compiled_dir
    _reload_tz_cache(compiled_dir)

    @info "Successfully built TimeZones"
end
