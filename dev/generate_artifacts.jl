using Base: SHA1
using Base.BinaryPlatforms: Platform
using CodecZlib: GzipDecompressorStream
using Downloads: download
using JSON3: JSON3
using HTTP: HTTP
using Pkg.Artifacts: bind_artifact!, load_artifacts_toml, unbind_artifact!
using SHA: SHA
using Tar: Tar
using TimeZones.TZData: tzdata_versions

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
        tarball = download(tarball_url, IOBuffer())

        # Compute the Artifact.toml `sha256` from the compressed archive.
        sha256 = bytes2hex(SHA.sha256(seekstart(tarball)))

        # Compute the Artifact.toml `git-tree-sha1`. Usually this is computed via
        # `Artifacts.create_artifact` but we want to avoid actually storing this data as an
        # artifact.
        git_tree_sha1 = SHA1(Tar.tree_hash(GzipDecompressorStream(seekstart(tarball))))
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
    @info "Determining latest tzdata version..."
    versions = tzdata_versions()
    latest_tzdata = last(versions)

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
