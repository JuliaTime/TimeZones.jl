using Dates, Documenter, TimeZones

DocMeta.setdocmeta!(TimeZones, :DocTestSetup, :(using TimeZones))

if haskey(ENV, "DOCTESTS") || haskey(ENV, "MAKE_DOCS") || haskey(ENV, "DEPLOY_DOCS")
    const DOCTESTS = get(ENV, "DOCTESTS", "false") == "true"
    const MAKE_DOCS = get(ENV, "MAKE_DOCS", "false") == "true"
    const DEPLOY_DOCS = get(ENV, "DEPLOY_DOCS", "false") == "true"
else
    const DOCTESTS = true
    const MAKE_DOCS = true
    const DEPLOY_DOCS = false
end

if MAKE_DOCS || DEPLOY_DOCS
    makedocs(
        modules=[TimeZones],
        format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
        pages=[
            "Introduction" => "index.md",
            "Types" => "types.md",
            "Converting" => "conversions.md",
            "Arithmetic" => "arithmetic.md",
            "Rounding" => "rounding.md",
            "Current Time" => "current.md",
            "Frequently Asked Questions" => "faq.md",
            "API – Public" => "api-public.md",
            "API – Private" => "api-private.md",
        ],
        sitename="TimeZones.jl",
        checkdocs=:exports,
        linkcheck=true,
        strict=true,
        doctest=DOCTESTS,
    )

    DEPLOY_DOCS && deploydocs(repo="github.com/JuliaTime/TimeZones.jl.git")
elseif DOCTESTS
    doctest(TimeZones)
end
