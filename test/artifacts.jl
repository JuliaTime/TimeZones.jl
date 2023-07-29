@testset "Artifacts" begin
    all_artifacts = select_downloadable_artifacts(
        TimeZones.TZData.ARTIFACT_TOML;
        include_lazy=true
    )
    non_lazy_artifacts = String[]

    # Collect all `tzdata` artifacts, assert that they are all lazy except for the default one
    for (name, meta) in all_artifacts
        if !startswith(name, "tzdata")
            continue
        end
        if get(meta, "lazy", "false") == "false"
            push!(non_lazy_artifacts, name)
        end
    end

    @test length(non_lazy_artifacts) == 1
    @test only(non_lazy_artifacts) == string("tzdata", TimeZones.TZData.DEFAULT_TZDATA_VERSION)
end
