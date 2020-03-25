#==
@recipe function f(xs::AbstractVector{<:ZonedDateTime}, ys)
    # if no zoned date times nothing to do but return empty list
    isempty(xs) && return xs
    tz = timezone(first(xs))  # convert all to same timezone as first one
    new_xs = DateTime.(astimezone.(xs, tz), Local)

    # xguide is the proper name for xlabel
    xguide := strip(get(plotattributes, :xguide, "") * " (timezone: $tz)")
    new_xs, ys
end

==#

@recipe f(::Type{T}, val::T) where {T<:ZonedDateTime} = (
    zdt ->  Dates.value(DateTime(zdt, UTC)),
    dt -> string(DateTime(Dates.UTM(dt))) * "+00:00",  # make clear we are in UTC
)
