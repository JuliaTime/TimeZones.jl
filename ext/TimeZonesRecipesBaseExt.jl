module TimeZonesRecipesBaseExt

using TimeZones
using RecipesBase: RecipesBase, @recipe

#==
Plot ZonedDateTime, on x-axis.
We convert it to DateTimes, in the local timezone,
and we list that timezone in the x-axis label.

This is just one of many options for how to display this info.
See this PR: https://github.com/JuliaTime/TimeZones.jl/pull/251#issuecomment-603806198
for details on the options and their tradeoffs.
==#
@recipe function f(xs::AbstractVector{<:ZonedDateTime}, ys)
    if !isempty(xs)
        tz = timezone(first(xs))  # convert all to same timezone as first one
        new_xs = DateTime.(astimezone.(xs, tz))

        # xguide is the proper name for xlabel
        label = get(plotattributes, :xguide, "")
        label *= isempty(label) ? "Time zone: $tz" : " ($tz)"
        xguide := label
        new_xs, ys
    else
        # Can't check timezone if empty so we just return an empty list
        [], ys
    end
end

end # module
