# https://github.com/JuliaLang/julia/pull/35973
if v"1.3.0" <= VERSION < v"1.6.0-DEV.84"
    # Declare a new `==` function to avoid type piracy and triggering invalidations
    function == end
    @inline ==(a, b) = Base.:(==)(a, b)

    function ==(a::Union{String, SubString{String}}, b::Union{String, SubString{String}})
        s = sizeof(a)
        s == sizeof(b) && 0 == Base._memcmp(a, b, s)
    end
end

if v"1.3.1-pre.18" <= VERSION < v"1.3.2"
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
elseif v"1.3.0" <= VERSION < v"1.6.0-beta1.15"
    # Issue does not exist in 1.3.0, and >= 1.4.0. Also, assume that the issue would also be
    # fixed on >= 1.3.2
    using Pkg.Artifacts: @artifact_str
elseif VERSION >= v"1.6.0-beta1.15"
    # Using Pkg instead of using LazyArtifacts is deprecated on 1.6.0-beta1.15 and 1.7.0-DEV.302
    using LazyArtifacts: @artifact_str
end
