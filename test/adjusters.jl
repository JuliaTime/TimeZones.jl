using Dates

# Basic truncation
warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
zdt = ZonedDateTime(DateTime(2014,10,15,23,59,58,57), warsaw)

@test trunc(zdt, Year) == ZonedDateTime(DateTime(2014), warsaw)
@test trunc(zdt, Month) == ZonedDateTime(DateTime(2014,10), warsaw)
@test trunc(zdt, Day) == ZonedDateTime(DateTime(2014,10,15), warsaw)
@test trunc(zdt, Hour) == ZonedDateTime(DateTime(2014,10,15,23), warsaw)
@test trunc(zdt, Minute) == ZonedDateTime(DateTime(2014,10,15,23,59), warsaw)
@test trunc(zdt, Second) == ZonedDateTime(DateTime(2014,10,15,23,59,58), warsaw)
@test trunc(zdt, Millisecond) == zdt

# Ambiguous hour truncation
dt = DateTime(2014,10,26,2)
@test ZonedDateTime(dt, warsaw, 1) != ZonedDateTime(dt, warsaw, 2)
@test trunc(ZonedDateTime(dt + Minute(59), warsaw, 1), Hour) == ZonedDateTime(dt, warsaw, 1)
@test trunc(ZonedDateTime(dt + Minute(59), warsaw, 2), Hour) == ZonedDateTime(dt, warsaw, 2)

# Sub-hourly offsets (Issue #33)
st_johns = first(compile("America/St_Johns", tzdata["northamerica"])) # UTC-3:30 or UTC-2:30
zdt = ZonedDateTime(DateTime(2016,8,18,17,57,56,513), st_johns)
@test trunc(zdt, Hour) == ZonedDateTime(DateTime(2016,8,18,17), st_johns)

# Adjuster functions
zdt = ZonedDateTime(DateTime(2013,9,9), warsaw) # Monday

@test TimeZones.firstdayofweek(zdt) == ZonedDateTime(DateTime(2013,9,9), warsaw)
@test TimeZones.lastdayofweek(zdt) == ZonedDateTime(DateTime(2013,9,15), warsaw)
@test TimeZones.firstdayofmonth(zdt) == ZonedDateTime(DateTime(2013,9,1), warsaw)
@test TimeZones.lastdayofmonth(zdt) == ZonedDateTime(DateTime(2013,9,30), warsaw)
@test TimeZones.firstdayofyear(zdt) == ZonedDateTime(DateTime(2013,1,1), warsaw)
@test TimeZones.lastdayofyear(zdt) == ZonedDateTime(DateTime(2013,12,31), warsaw)
@test TimeZones.firstdayofquarter(zdt) == ZonedDateTime(DateTime(2013,7,1), warsaw)
@test TimeZones.lastdayofquarter(zdt) == ZonedDateTime(DateTime(2013,9,30), warsaw)


# TODO: Should be in Dates.
@test Dates.lastdayofyear(DateTime(2013,9,9)) == DateTime(2013,12,31)
