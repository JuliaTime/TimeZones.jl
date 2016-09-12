import Base.Dates: Second

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
fixed = FixedTimeZone("Fixed", -7200, 3600)

# ZonedDateTime accessors
zdt = ZonedDateTime(DateTime(2014,6,12,23,59,58,57), fixed)
@test TimeZones.localtime(zdt) == DateTime(2014,6,12,23,59,58,57)
@test TimeZones.utc(zdt) == DateTime(2014,6,13,0,59,58,57)

@test TimeZones.days(zdt) == 735396
@test TimeZones.hour(zdt) == 23
@test TimeZones.minute(zdt) == 59
@test TimeZones.second(zdt) == 58
@test TimeZones.millisecond(zdt) == 57

# Make sure that Base.Dates accessors work with ZonedDateTime.
@test Dates.year(zdt) == 2014
@test Dates.month(zdt) == 6
@test Dates.week(zdt) == 24
@test Dates.day(zdt) == 12
@test Dates.dayofmonth(zdt) == 12
@test Dates.yearmonth(zdt) == (2014, 6)
@test Dates.monthday(zdt) == (6, 12)
@test Dates.yearmonthday(zdt) == (2014, 6, 12)

# Vectorized accessors
# Note: repmat is used over broadcast to test for size and equality.
arr = repmat([zdt], 10)
@test TimeZones.hour.(arr) == repmat([23], 10)
@test TimeZones.minute.(arr) == repmat([59], 10)
@test TimeZones.second.(arr) == repmat([58], 10)
@test TimeZones.millisecond.(arr) == repmat([57], 10)

@test Dates.year.(arr) == repmat([2014], 10)
@test Dates.month.(arr) == repmat([6], 10)
@test Dates.day.(arr) == repmat([12], 10)
@test Dates.dayofmonth.(arr) == repmat([12], 10)
@test Dates.yearmonth.(arr) == repmat([(2014, 6)], 10)
@test Dates.monthday.(arr) == repmat([(6, 12)], 10)
@test Dates.yearmonthday.(arr) == repmat([(2014, 6, 12)], 10)
