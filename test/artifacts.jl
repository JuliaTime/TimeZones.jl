using LazyArtifacts, TimeZones, Test

@testset "Artifacts" begin
    all_artifacts = LazyArtifacts.select_downloadable_artifacts(TimeZones.TZData.ARTIFACT_TOML; include_lazy=true)
    lazy_artifacts = String[]

    # Collect all `tzdata` artifacts, assert that they are all lazy except for the default one
    for (name, meta) in all_artifacts
        if !startswith(name, "tzdata")
            continue
        end
        if get(meta, "lazy", "false") == "false"
            push!(lazy_artifacts, name)
        end
    end

    @test length(lazy_artifacts) == 1
    @test only(lazy_artifacts) == string("tzdata", TimeZones.TZData.DEFAULT_TZDATA_VERSION)
end
