# Note: recipes seem to need to use short-form functions
@recipe f(::Type{T}, val::T) where {T<:ZonedDateTime} = (
    zdt -> Dates.value(DateTime(zdt, UTC)),
    dt -> string(DateTime(Dates.UTM(dt))),
)
