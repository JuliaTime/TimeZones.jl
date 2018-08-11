import Compat.Dates: Hour, Minute, Second, Millisecond,
    days, hour, minute, second, millisecond

"""
    localtime(::Localized) -> DateTime

Creates a local or civil `DateTime` from the given `Localized`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T08:11:24`.
"""
localtime(zdt::Localized) = zdt.utc_datetime + zdt.zone.offset

"""
    utc(::Localized) -> DateTime

Creates a utc `DateTime` from the given `Localized`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T12:11:24`.
"""
utc(zdt::Localized) = zdt.utc_datetime

"""
    timezone(::Localized) -> TimeZone

Returns the `TimeZone` used by the `Localized`.
"""
timezone(zdt::Localized) = zdt.timezone

days(zdt::Localized) = days(localtime(zdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(zdt::Localized) = $accessor(localtime(zdt))
        $period(zdt::Localized) = $period($accessor(zdt))
    end
end
