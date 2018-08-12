import Compat.Dates
import Compat.Dates: Second

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
fixed = FixedTimeZone("Fixed", -7200, 3600)

# Localized accessors
ldt = Localized(DateTime(2014,6,12,23,59,58,57), fixed)
@test TimeZones.localtime(ldt) == DateTime(2014,6,12,23,59,58,57)
@test TimeZones.utc(ldt) == DateTime(2014,6,13,0,59,58,57)

@test TimeZones.days(ldt) == 735396
@test TimeZones.hour(ldt) == 23
@test TimeZones.minute(ldt) == 59
@test TimeZones.second(ldt) == 58
@test TimeZones.millisecond(ldt) == 57

# Make sure that Dates accessors work with Localized.
@test Dates.year(ldt) == 2014
@test Dates.month(ldt) == 6
@test Dates.week(ldt) == 24
@test Dates.day(ldt) == 12
@test Dates.dayofmonth(ldt) == 12
@test Dates.yearmonth(ldt) == (2014, 6)
@test Dates.monthday(ldt) == (6, 12)
@test Dates.yearmonthday(ldt) == (2014, 6, 12)

# Vectorized accessors
# Note: fill is used to test for size and equality.
n = 10
arr = fill(ldt, n)
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
