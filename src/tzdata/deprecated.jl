# BEGIN TimeZones 1.12 deprecations

function build(
    version::AbstractString,
    regions::AbstractVector{<:AbstractString},
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="",
)
    Base.depwarn(
        "`$build(version, regions, tz_source_dir, compiled_dir)` is deprecated with no " *
        "direct replacement, see `$build(version, working_dir)` as an alternative.",
        :build,
    )

    url = tzdata_url(version)
    tzdata_archive_file = joinpath(tempdir(), basename(url))
    if !isfile(tzdata_archive_file)
        @info "Downloading tzdata $version archive"
        mkpath(archive_dir)
        download(url, tzdata_archive_file)
    end

    if !isdir(source_dir)
        @info "Decompressing tzdata $version region data"
        isarchive(tzdata_archive_file) || error("Invalid archive: $tzdata_archive_file")
        mkpath(source_dir)

        # TODO: Confirm that "utc" was ever included in the tzdata archives
        build_regions = intersect!(list(tzdata_archive_file), regions)
        unpack(tzdata_archive_file, source_dir, build_regions)

        for custom_region in CUSTOM_REGIONS
            cp(joinpath(CUSTOM_REGION_DIR, custom_region), joinpath(source_dir, custom_region))
            push!(build_regions, custom_region)
        end
    else
        build_regions = intersect!(readdir(source_dir), regions)
    end

    if !isdir(compiled_dir)
        @info "Compiling tzdata $version region data"
        mkpath(compiled_dir)
        tz_source = TZSource(joinpath.(source_dir, build_regions))
        compile(tz_source, compiled_dir)
    end

    return version
end

function build()
    Base.depwarn(
        """`$build()` is deprecated, use
        ```
        let version = $tzdata_version()
            $build(version, tempdir())
            version
        end
        ```
        instead.""",
        :build
    )

    version = tzdata_version()
    working_dir = tempdir()
    build(version, working_dir)
    return version
end

function build(version::AbstractString; returned::Symbol=:version)
    if returned === :version
        Base.depwarn(
            """`$build(version; returned=:version)` is deprecated, use
            ```
            let
                $build(version, tempdir())
                version
            end
            ```
            instead.""",
            :build,
        )
    elseif returned === :namedtuple
        Base.depwarn(
            """`$build(version; returned=:namedtuple)` is deprecated, use
            ```
            let working_dir = tempdir()
                compiled_dir = $build(version, working_dir)
                tz_source_dir = joinpath(working_dir, $(_tz_source_relative_dir)(version))
                (; version, tz_source_dir, compiled_dir)
            end
            ```
            instead.""",
            :build
        )
    else
        throw(ArgumentError("Unhandled return option: $returned"))
    end

    working_dir = tempdir()
    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(version))

    compiled_dir = build(version, working_dir)
    
    if returned === :version
        return version
    elseif returned === :namedtuple
        return (; version, tz_source_dir, compiled_dir)
    end
end

# BEGIN TimeZones 1.12 deprecations
