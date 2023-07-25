# The default tz source files we care about. See "ftp://ftp.iana.org/tz/data/Makefile"
# "PRIMARY_YDATA" for listing of tz source files to include.
const STANDARD_REGIONS = [
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica", "utc",
]

# Legacy tz source files TimeZones.jl typically ignores ("YDATA" in Makefile).
const LEGACY_REGIONS = [
    "pacificnew", "etcetera", "backward",
]

# Note: The "utc" region is a made up tz source file and isn't included in the archives.
const CUSTOM_REGION_DIR = joinpath(@__DIR__, "..", "..", "deps", "tzsource_custom")
const CUSTOM_REGIONS = [
    "utc",
]

const REGIONS = [STANDARD_REGIONS; LEGACY_REGIONS]


function build(
    version::AbstractString,
    regions::AbstractVector{<:AbstractString},
    tz_source_dir::AbstractString="",
    compiled_dir::AbstractString="",
)
    # Validate that the version specified is in the Artifact.toml
    tzdata_hash = artifact_hash("tzdata$version", ARTIFACT_TOML)
    if tzdata_hash === nothing
        error("tzdata$version is not present in the Artifacts.toml")
    end

    artifact_dir = @artifact_str "tzdata$version"

    # TODO: Deprecate skipping tzdata installation step or use `nothing` instead
    if !isempty(tz_source_dir)
        @info "Installing $version tzdata region data"
        region_paths = vcat(
            joinpath.(artifact_dir, intersect!(readdir(artifact_dir), regions)),
            joinpath.(CUSTOM_REGION_DIR, CUSTOM_REGIONS),
        )
        for path in region_paths
            cp(path, joinpath(tz_source_dir, basename(path)), force=true)
        end

        # Update the set of regions to compile the regions that existed in the artifact
        # directory and the custom regions. There are some subtleties to this logic:
        #
        # - Will skips compiling non-existent regions that were specified (but only when
        #   `tz_source_dir` is used)
        # - Custom regions are compiled even when not requested when `tz_source_dir` is used
        # - Compile ignores extra files stored in the `tz_source_dir`
        #
        # TODO: In the future it's probably more sensible to get away from this subtle
        # behaviour and just compile all files present in the `tz_source_dir`.
        regions = basename.(region_paths)
    end

    # TODO: Deprecate skipping conversion step or use `nothing` instead
    if !isempty(compiled_dir)
        @info "Converting tz source files into TimeZone data"
        tz_source = TZSource(joinpath.(tz_source_dir, regions))
        compile(tz_source, compiled_dir)
    end

    return version
end

function build(version::AbstractString=tzdata_version(); returned::Symbol=:version)
    tz_source_dir = _tz_source_dir(version)
    compiled_dir = _compiled_dir(version)

    # Empty directories to avoid having left over files from previous builds.
    isdir(tz_source_dir) && rm(tz_source_dir, recursive=true)
    isdir(compiled_dir) && rm(compiled_dir, recursive=true)
    mkpath(tz_source_dir)
    mkpath(compiled_dir)

    version = build(version, REGIONS, tz_source_dir, compiled_dir)

    if returned === :version
        return version
    elseif returned === :namedtuple
        return (; version, tz_source_dir, compiled_dir)
    else
        throw(ArgumentError("Unhandled return option: $returned"))
    end
end

_archive_relative_dir() = "archive"
_tz_source_relative_dir(version::AbstractString) = joinpath("tzsource", version)
_compiled_relative_dir(version::AbstractString) = joinpath("compiled", "tzjf", "v$(TZJFile.DEFAULT_VERSION)", version)

# Only accepts a real tzdata version (not latest)
function build(version::AbstractString, working_dir::AbstractString)
    tzdata_archive_dir = joinpath(working_dir, _archive_relative_dir())
    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(version))
    compiled_dir = joinpath(working_dir, _compiled_relative_dir(version))

    url = tzdata_url(version)
    tzdata_archive_file = joinpath(tzdata_archive_dir, basename(url))
    if !isfile(tzdata_archive_file)
        @info "Downloading tzdata $version archive"
        mkpath(tzdata_archive_dir)
        download(url, tzdata_archive_file)
    end

    if !isdir(tz_source_dir)
        @info "Decompressing tzdata $version region data"
        mkpath(tz_source_dir)

        # TODO: Confirm that "utc" was ever included in the tzdata archives
        regions = intersect!(list(tzdata_archive_file), REGIONS)
        unpack(tzdata_archive_file, tz_source_dir, regions; verbose=true)

        for custom_region in CUSTOM_REGIONS
            cp(joinpath(CUSTOM_REGION_DIR, custom_region), joinpath(tz_source_dir, custom_region))
            push!(regions, custom_region)
        end
    else
        regions = readdir(tz_source_dir)
    end

    if !isdir(compiled_dir)
        @info "Compiling tzdata $version region data"
        mkpath(compiled_dir)
        tz_source = TZSource(joinpath.(tz_source_dir, regions))
        compile(tz_source, compiled_dir)
    end

    return compiled_dir
end

function cleanup(version::AbstractString, working_dir::AbstractString)
    tzdata_archive_file = joinpath(working_dir, _archive_relative_dir(), basename(tzdata_url(version)))
    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(version))
    compiled_dir = joinpath(working_dir, _compiled_relative_dir(version))

    isfile(tzdata_archive_file) && rm(tzdata_archive_file)
    isdir(tz_source_dir) && rm(tz_source_dir; recursive=true)
    isdir(compiled_dir) && rm(compiled_dir; recursive=true)

    return nothing
end
