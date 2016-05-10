localtime(zdt::ZonedDateTime) = zdt.utc_datetime + zdt.zone.offset
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
