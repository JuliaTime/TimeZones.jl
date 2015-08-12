import Base.Dates: Year, Month, Day, Hour, Minute, Second, Millisecond

# Basic truncation
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
zdt = ZonedDateTime(DateTime(2014,10,15,23,59,58,57), warsaw)

@test trunc(zdt, Year) == ZonedDateTime(DateTime(2014), warsaw)
@test trunc(zdt, Month) == ZonedDateTime(DateTime(2014,10), warsaw)
@test trunc(zdt, Day) == ZonedDateTime(DateTime(2014,10,15), warsaw)
@test trunc(zdt, Hour) == ZonedDateTime(DateTime(2014,10,15,23), warsaw)
@test trunc(zdt, Minute) == ZonedDateTime(DateTime(2014,10,15,23,59), warsaw)
@test trunc(zdt, Second) == ZonedDateTime(DateTime(2014,10,15,23,59,58), warsaw)
@test trunc(zdt, Millisecond) == zdt

# Ambigious hour truncation
dt = DateTime(2014,10,26,2)
@test ZonedDateTime(dt, warsaw, 1) != ZonedDateTime(dt, warsaw, 2)
@test trunc(ZonedDateTime(dt + Minute(59), warsaw, 1), Hour) == ZonedDateTime(dt, warsaw, 1)
@test trunc(ZonedDateTime(dt + Minute(59), warsaw, 2), Hour) == ZonedDateTime(dt, warsaw, 2)