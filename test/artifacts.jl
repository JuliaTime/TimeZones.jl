@testset "Artifacts" begin
    @testset "unicode-cldr" begin
        platforms = [
            Platform("x86_64", "windows"),
            Platform("i686", "windows"),
        ]

        for platform in platforms
            dict = select_downloadable_artifacts(
                joinpath(@__DIR__, "..", "Artifacts.toml");
                platform,
                include_lazy=true,
            )
            @test length(dict) == 1

            name, info = first(dict)
            @test startswith(name, "unicode-cldr")
            @test get(info, "lazy", false) == false
        end
    end
end
