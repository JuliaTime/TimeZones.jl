using Documenter, TimeZones

makedocs(
    sitename="TimeZones.jl",
    pages = [
        "Introduction" => "index.md",
        "Types" => "types.md",
        "Converting" => "conversions.md",
        "Arithmetic" => "arithmetic.md",
        "Rounding" => "rounding.md",
        "Current Time" => "current.md",
        "Frequently Asked Questions" => "faq.md",
    ],
    html_prettyurls=false,  # makes local builds work
    linkcheck=true,
    linkcheck_ignore=[r"^ftp://.*"],
    strict=true,
)
