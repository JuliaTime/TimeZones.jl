import TimeZones.Olsen: Time, second, period
import Base.Dates: Hour, Minute, Second

# Time seconds constructor
t = Time(5025)
@test t.hour == 1
@test t.minute == 23
@test t.second == 45
@test second(t) == 5025
@test period(t) == Hour(1) + Minute(23) + Second(45)

t = Time(-5025)
@test t.hour == 1
@test t.minute == 23
@test t.second == 45
@test second(t) == -5025
@test period(t) == -(Hour(1) + Minute(23) + Second(45))

@test Time(1,23,45) + Time(-1,23,45) == Time(0)
@test Time(1,23,45) - Time(1,23,45) == Time(0)

@test Time("1:23:45") == Time(1,23,45)
@test Time("-1:23:45") == Time(-1,23,45)
@test Time("-1:23:45") == Time(-1,23,45)
@test_throws Exception Time("1:-23:45")
@test_throws Exception Time("1:23:-45")
