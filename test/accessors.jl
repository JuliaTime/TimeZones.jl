import Dates
using Dates: Second, Millisecond

warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
fixed = FixedTimeZone("Fixed", -7200, 3600)

# ZonedDateTime accessors
zdt = ZonedDateTime(DateTime(2014,6,12,23,59,58,57), fixed)
@test TimeZones.localtime(zdt) == DateTime(2014,6,12,23,59,58,57)
@test TimeZones.utc(zdt) == DateTime(2014,6,13,0,59,58,57)
@test timezone(zdt) === fixed

@test TimeZones.days(zdt) == 735396
@test TimeZones.hour(zdt) == 23
@test TimeZones.minute(zdt) == 59
@test TimeZones.second(zdt) == 58
@test TimeZones.millisecond(zdt) == 57

@test eps(zdt) == Millisecond(1)

# Make sure that Dates accessors work with ZonedDateTime.
@test Dates.year(zdt) == 2014
@test Dates.month(zdt) == 6
@test Dates.week(zdt) == 24
@test Dates.day(zdt) == 12
@test Dates.dayofmonth(zdt) == 12
@test Dates.yearmonth(zdt) == (2014, 6)
@test Dates.monthday(zdt) == (6, 12)
@test Dates.yearmonthday(zdt) == (2014, 6, 12)

# Vectorized accessors
# Note: fill is used to test for size and equality.
n = 10
arr = fill(zdt, n)
@test TimeZones.hour.(arr) == fill(23, n)
@test TimeZones.minute.(arr) == fill(59, n)
@test TimeZones.second.(arr) == fill(58, n)
@test TimeZones.millisecond.(arr) == fill(57, n)

@test Dates.year.(arr) == fill(2014, n)
@test Dates.month.(arr) == fill(6, n)
@test Dates.day.(arr) == fill(12, n)
@test Dates.dayofmonth.(arr) == fill(12, n)
@test Dates.yearmonth.(arr) == fill((2014, 6), n)
@test Dates.monthday.(arr) == fill((6, 12), n)
@test Dates.yearmonthday.(arr) == fill((2014, 6, 12), n)
