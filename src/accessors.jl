import Compat.Dates: Hour, Minute, Second, Millisecond,
    days, hour, minute, second, millisecond

"""
    localtime(::Localized) -> DateTime

Creates a local or civil `DateTime` from the given `Localized`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T08:11:24`.
"""
localtime(ldt::Localized) = ldt.utc_datetime + ldt.zone.offset

"""
    utc(::Localized) -> DateTime

Creates a utc `DateTime` from the given `Localized`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T12:11:24`.
"""
utc(ldt::Localized) = ldt.utc_datetime

"""
    timezone(::Localized) -> TimeZone

Returns the `TimeZone` used by the `Localized`.
"""
timezone(ldt::Localized) = ldt.timezone

days(ldt::Localized) = days(localtime(ldt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(ldt::Localized) = $accessor(localtime(ldt))
        $period(ldt::Localized) = $period($accessor(ldt))
    end
end
