using Base: SHA1
using JSON: JSON
using HTTP: HTTP
using Inflate: inflate_gzip
using Pkg.Artifacts
using SHA: sha256
using Tar: Tar
using TimeZones.TZData: tzdata_versions


# Code loosely based upon: https://julialang.github.io/Pkg.jl/dev/artifacts/#Using-Artifacts-1
function bind_artifact_url!(artifacts_toml::String, name::String, url::String)
    # Query the `Artifacts.toml` file for the hash associated with artifact name. If no such
    # binding exists within the file then `nothing` will be returned.
    artifact_hash = Artifacts.artifact_hash(name, artifacts_toml)

    if artifact_hash === nothing
        @info "Processing new artifact: $name"

        archive = download(url)
        try
            # Compute the `sha256` of the archive.
            archive_sha = bytes2hex(open(sha256, archive))

            # Compute the `git-tree-sha1`. Usually this is computed via
            # `create_artifact` but we want to avoid actually storing this data as an
            # artifact.
            artifact_hash = SHA1(Tar.tree_hash(IOBuffer(inflate_gzip(archive))))

            bind_artifact!(
                artifacts_toml,
                name,
                artifact_hash,
                lazy=true,
                download_info=[(url, archive_sha)],
            )
        finally
            rm(archive)
        end
    end
end

function update_artifacts!(artifacts_toml::String)
    @info "Checking for missing tzdata versions..."
    versions = tzdata_versions()
    for version in versions
        artifact_name = "tzdata$version"
        url = "https://data.iana.org/time-zones/releases/tzdata$version.tar.gz"
        bind_artifact_url!(artifacts_toml, artifact_name, url)
    end
    latest_tzdata = last(versions)

    @info "Checking for latest Unicode CLDR release..."
    response = HTTP.get("https://api.github.com/repos/unicode-org/cldr/releases/latest")
    json = JSON.parse(String(response.body))
    latest_unicode_cldr = json["tag_name"]  # latest release

    @info "Latest Unicode CLDR release: $latest_unicode_cldr"
    url = "https://github.com/unicode-org/cldr/archive/$latest_unicode_cldr.tar.gz"
    bind_artifact_url!(artifacts_toml, "unicode-cldr-$latest_unicode_cldr", url)

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
