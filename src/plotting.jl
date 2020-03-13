# Note: type-recipes seem to need to use short-form functions
@recipe function f(::Type{<:ZonedDateTime}, val::ZonedDateTime)
    return (
        zdt -> Dates.value(DateTime(zdt, UTC)),
        dt -> string(DateTime(Dates.UTM(dt))),
    )
end
