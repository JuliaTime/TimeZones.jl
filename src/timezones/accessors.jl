"""
    localtime(::ZonedDateTime) -> DateTime

Creates a local or civil `DateTime` from the given `ZonedDateTime`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T08:11:24`.
"""
localtime(zdt::ZonedDateTime) = zdt.utc_datetime + zdt.zone.offset

"""
    utc(::ZonedDateTime) -> DateTime

Creates a utc `DateTime` from the given `ZonedDateTime`. For example the
`2014-05-30T08:11:24-04:00` would return `2014-05-30T12:11:24`.
"""
utc(zdt::ZonedDateTime) = zdt.utc_datetime

days(zdt::ZonedDateTime) = days(localtime(zdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(zdt::ZonedDateTime) = $accessor(localtime(zdt))
        @vectorize_1arg ZonedDateTime $accessor

        $period(zdt::ZonedDateTime) = $period($accessor(zdt))
    end
end
