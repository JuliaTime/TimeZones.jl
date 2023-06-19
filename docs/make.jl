using Dates, Documenter, TimeZones

DocMeta.setdocmeta!(TimeZones, :DocTestSetup, :(using TimeZones))

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
    # RUN_DOCTESTS=true is set by the doctest CI jobs
    doctest=get(ENV, "RUN_DOCTESTS", nothing) == "true",
)
