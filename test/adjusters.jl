using Compat.Dates

# Basic truncation
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
zdt = Localized(DateTime(2014,10,15,23,59,58,57), warsaw)

@test trunc(zdt, Year) == Localized(DateTime(2014), warsaw)
@test trunc(zdt, Month) == Localized(DateTime(2014,10), warsaw)
@test trunc(zdt, Day) == Localized(DateTime(2014,10,15), warsaw)
@test trunc(zdt, Hour) == Localized(DateTime(2014,10,15,23), warsaw)
@test trunc(zdt, Minute) == Localized(DateTime(2014,10,15,23,59), warsaw)
@test trunc(zdt, Second) == Localized(DateTime(2014,10,15,23,59,58), warsaw)
@test trunc(zdt, Millisecond) == zdt

# Ambiguous hour truncation
dt = DateTime(2014,10,26,2)
@test Localized(dt, warsaw, 1) != Localized(dt, warsaw, 2)
@test trunc(Localized(dt + Minute(59), warsaw, 1), Hour) == Localized(dt, warsaw, 1)
@test trunc(Localized(dt + Minute(59), warsaw, 2), Hour) == Localized(dt, warsaw, 2)

# Sub-hourly offsets (Issue #33)
st_johns = resolve("America/St_Johns", tzdata["northamerica"]...)   # UTC-3:30 or UTC-2:30
zdt = Localized(DateTime(2016,8,18,17,57,56,513), st_johns)
@test trunc(zdt, Hour) == Localized(DateTime(2016,8,18,17), st_johns)

# Adjuster functions
zdt = Localized(DateTime(2013,9,9), warsaw) # Monday

@test TimeZones.firstdayofweek(zdt) == Localized(DateTime(2013,9,9), warsaw)
@test TimeZones.lastdayofweek(zdt) == Localized(DateTime(2013,9,15), warsaw)
@test TimeZones.firstdayofmonth(zdt) == Localized(DateTime(2013,9,1), warsaw)
@test TimeZones.lastdayofmonth(zdt) == Localized(DateTime(2013,9,30), warsaw)
@test TimeZones.firstdayofyear(zdt) == Localized(DateTime(2013,1,1), warsaw)
@test TimeZones.lastdayofyear(zdt) == Localized(DateTime(2013,12,31), warsaw)
@test TimeZones.firstdayofquarter(zdt) == Localized(DateTime(2013,7,1), warsaw)
@test TimeZones.lastdayofquarter(zdt) == Localized(DateTime(2013,9,30), warsaw)


# TODO: Should be in Dates.
@test Dates.lastdayofyear(DateTime(2013,9,9)) == DateTime(2013,12,31)
