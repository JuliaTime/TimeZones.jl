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

"""
    isstrict(ldt::Localized) -> Bool

Returns whether the localized datetime is strict
(e.g., cannot represent non-existent or ambiguous hours).
"""
isstrict(ldt::Localized{T, true}) where T = true
isstrict(ldt::Localized{T, false}) where T = false

"""
    isvalid(ldt::Localized) -> Bool

Returns wether the localized datetime is valid (e.g., exists and is not amibiguous)
"""
Base.isvalid(ldt::Localized) = !isa(ldt.zone, InvalidTimeZone)

"""
    isambiguous(ldt::Localized) -> Bool

Returns whether the localized datetime is ambiguous.
"""
isambiguous(ldt::Localized) = isa(ldt.zone, Ambiguous)

"""
    isnonexistent(ldt::Localized) -> Bool

Returns whether the localized datetime is non-existent.
"""
isnonexistent(ldt::Localized) = isa(ldt.zone, NonExistent)

days(ldt::Localized) = days(localtime(ldt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(ldt::Localized) = $accessor(localtime(ldt))
        $period(ldt::Localized) = $period($accessor(ldt))
    end
end
