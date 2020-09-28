using Dates: Hour, Minute, Second, Millisecond, days, hour, minute, second, millisecond

"""
    timezone(::ZonedDateTime) -> TimeZone

Returns the `TimeZone` used by the `ZonedDateTime`.
"""
timezone(zdt::ZonedDateTime) = zdt.timezone

Dates.days(zdt::ZonedDateTime) = days(DateTime(zdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        Dates.$accessor(zdt::ZonedDateTime) = $accessor(DateTime(zdt))
        Dates.$period(zdt::ZonedDateTime) = $period($accessor(zdt))
    end
end

Base.eps(::ZonedDateTime) = Millisecond(1)
