if VERSION == v"1.3.1"
    using Pkg.Artifacts: do_artifact_str, find_artifacts_toml, load_artifacts_toml

    # A copy of `Pkg.Artifacts.@artifact_str` where `name` is properly escaped on
    # Julia 1.3.1
    # https://github.com/JuliaLang/Pkg.jl/issues/1912
    # https://github.com/JuliaLang/Pkg.jl/pull/1580
    macro artifact_str(name)
        # Load Artifacts.toml at compile time, so that we don't have to use `__source__.file`
        # at runtime, which gets stale if the `.ji` file is relocated.
        local artifacts_toml = find_artifacts_toml(string(__source__.file))
        if artifacts_toml === nothing
            error(string(
                "Cannot locate '(Julia)Artifacts.toml' file when attempting to use artifact '",
                name,
                "' in '",
                __module__,
                "'",
            ))
        end

        local artifact_dict = load_artifacts_toml(artifacts_toml)
        return quote
            # Invalidate .ji file if Artifacts.toml file changes
            Base.include_dependency($(artifacts_toml))

            # Use invokelatest() to introduce a compiler barrier, preventing many backedges from being added
            # and slowing down not only compile time, but also `.ji` load time.  This is critical here, as
            # artifact"" is used in other modules, so we don't want to be spreading backedges around everywhere.
            Base.invokelatest(do_artifact_str, $(esc(name)), $(artifact_dict), $(artifacts_toml), $__module__)
        end
    end
elseif VERSION >= v"1.3.0"
    # Issue does not exist in 1.3.0, and >= 1.4.0. Also, assume that the issue would also be
    # fixed on >= 1.3.2
    using Pkg.Artifacts: @artifact_str
end
