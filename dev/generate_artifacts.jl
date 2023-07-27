using Base: SHA1
using Base.BinaryPlatforms: HostPlatform, Platform
using CodecZlib: GzipDecompressorStream
using Downloads: download
using JSON3: JSON3
using HTTP: HTTP
using Pkg.Artifacts: AbstractPlatform, artifact_hash, artifact_meta, bind_artifact!,
    load_artifacts_toml, unbind_artifact!
using SHA: SHA
using Tar: Tar
using TimeZones.TZData: tzdata_versions


function artifact_checksums(tarball_url::AbstractString)
    tarball = download(tarball_url, IOBuffer())

    # Compute the Artifact.toml `sha256` from the compressed archive.
    sha256 = bytes2hex(SHA.sha256(seekstart(tarball)))

    # Compute the Artifact.toml `git-tree-sha1`. Usually this is computed via
    # `Artifacts.create_artifact` but we want to avoid actually storing this data as an
    # artifact.
    git_tree_sha1 = SHA1(Tar.tree_hash(GzipDecompressorStream(seekstart(tarball))))

    return git_tree_sha1, sha256
end

# Code loosely based upon: https://julialang.github.io/Pkg.jl/dev/artifacts/#Using-Artifacts-1
function bind_artifact_url!(
    artifacts_toml::String,
    name::String,
    url::String;
    lazy::Bool=true,
    platform::Union{AbstractPlatform,Nothing}=nothing,
)
    p = something(platform, HostPlatform())

    # Query the `Artifacts.toml` file for the hash associated with artifact name. If no such
    # binding exists within the file then `nothing` will be returned.
    git_tree_sha1 = artifact_hash(name, artifacts_toml; platform=p)

    if git_tree_sha1 === nothing
        @info "Processing new artifact: $name"
        git_tree_sha1, sha256 = artifact_checksums(url)
    else
        meta = artifact_meta(name, artifacts_toml; platform=p)
        sha256 = only(meta["download"])["sha256"]
    end

    download_info = [(url, sha256)]

    # Must unbind before we can call bind on an already bound artifact
    unbind_artifact!(artifacts_toml, name)
    bind_artifact!(artifacts_toml, name, git_tree_sha1; lazy, platform, download_info)
end

function update_uncode_cldr_artifacts!(artifacts_toml::AbstractString)
    @info "Checking for latest Unicode CLDR release..."
    response = HTTP.get("https://api.github.com/repos/unicode-org/cldr/releases/latest")
    json = JSON3.read(response.body)
    latest_unicode_cldr = json.tag_name  # latest release

    @info "Latest Unicode CLDR release: $latest_unicode_cldr"
    url = "https://github.com/unicode-org/cldr/archive/$latest_unicode_cldr.tar.gz"

    artifact_dict = load_artifacts_toml(artifacts_toml)
    unicode_artifacts = filter(startswith("unicode-cldr-"), keys(artifact_dict))

    # Determine the checksum information from the artifacts or the download.
    name = "unicode-cldr-$latest_unicode_cldr"
    if name in unicode_artifacts
        # Assumes that the same artifact is used across various platforms. That is true
        # for our use of the unicode-cldr artifact.
        info = first(artifact_dict[name])
        git_tree_sha1 = SHA1(info["git-tree-sha1"])
        sha256 = only(info["download"])["sha256"]
    else
        @info "Processing new artifact: $name"
        git_tree_sha1, sha256 = artifact_checksums(url)
    end

    download_info = [(url, sha256)]
    platforms = [
        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
    ]

    # Clear out old unicode-cldr versions by unbinding all of the relevant artifacts and
    # only binding the latest version.
    unbind_artifact!.(artifacts_toml, unicode_artifacts)
    for platform in platforms
        bind_artifact!(artifacts_toml, name, git_tree_sha1; platform, download_info)
    end

    return latest_unicode_cldr
end


function update_artifacts!(artifacts_toml::String)
    @info "Checking for missing tzdata versions..."
    versions = tzdata_versions()
    latest_tzdata = last(versions)

    for version in versions
        artifact_name = "tzdata$version"
        url = "https://data.iana.org/time-zones/releases/tzdata$version.tar.gz"
        lazy = version != latest_tzdata
        bind_artifact_url!(artifacts_toml, artifact_name, url; lazy)
    end

    latest_unicode_cldr = update_uncode_cldr_artifacts!(artifacts_toml)

    # Display the information on the latest releases which is useful for updating the
    # TimeZones package defaults.
    println("""

        Latest releases:
           tzdata:       $latest_tzdata
           unicode-cldr: $latest_unicode_cldr
        """
    )
end

# Execute with: `julia --project=dev/ dev/generate_artifacts.jl`
if abspath(PROGRAM_FILE) == @__FILE__
    artifact_toml = if length(ARGS) >= 1
        ARGS[1]
    else
        joinpath(@__DIR__, "..", "Artifacts.toml")
    end

    @time update_artifacts!(artifact_toml)
end
