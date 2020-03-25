@recipe function f(xs::AbstractVector{<:ZonedDateTime}, ys)
    # if no zoned date times nothing to do but return empty list
    isempty(xs) && return xs
    tz = timezone(first(xs))  # convert all to same timezone as first one
    new_xs = DateTime.(astimezone.(xs, tz), Local)

    # xguide is the proper name for xlabel
    label = get(plotattributes, :xguide, "")
    if !isempty(label)
        label *= " "  # leave space between original label and the timezone info
    end
    xguide := label *= "(timezone: $tz)"
    new_xs, ys
end
