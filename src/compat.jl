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

if v"1.3.0" <= VERSION < v"1.6.0-beta1.15"
    # Issue does not exist in 1.3.0, and >= 1.4.0. Also, assume that the issue would also be
    # fixed on >= 1.3.2
    using Pkg.Artifacts: @artifact_str
elseif VERSION >= v"1.6.0-beta1.15"
    # Using Pkg instead of using LazyArtifacts is deprecated on 1.6.0-beta1.15 and 1.7.0-DEV.302
    using LazyArtifacts: @artifact_str
end
