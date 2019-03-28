using Dates, Documenter, TimeZones

makedocs(
    modules=[TimeZones],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
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
)
