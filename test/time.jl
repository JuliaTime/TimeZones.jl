import TimeZones: Time, value, hour, minute, second, hourminutesecond

# Time seconds constructor
t = Time(5025)
@test hour(t) == 1
@test minute(t) == 23
@test second(t) == 45
@test value(t) == 5025
@test hourminutesecond(t) == (1, 23, 45)

t = Time(-5025)
@test hour(t) == -1
@test minute(t) == -23
@test second(t) == -45
@test value(t) == -5025
@test hourminutesecond(t) == (-1, -23, -45)

t = Time(0,61,61)
@test t == Time(1,2,1)
@test value(t) == 3721

t = Time(1,-23,-45)
@test t == Time(0,36,15)
@test value(t) == 2175

# Time String constructor
@test Time("1") == Time(1,0,0)  # See Pacific/Apia rules for an example.
@test Time("1:23") == Time(1,23,0)
@test Time("1:23:45") == Time(1,23,45)
@test Time("-1") == Time(-1,0,0)
@test Time("-1:23") == Time(-1,-23,0)
@test Time("-1:23:45") == Time(-1,-23,-45)
@test_throws ArgumentError Time("1:-23:45")
@test_throws ArgumentError Time("1:23:-45")
@test_throws ArgumentError Time("1:23:45:67")

@test string(Time(1,23,45)) == "01:23:45"
@test string(Time(-1,-23,-45)) == "-01:23:45"
@test string(Time(0,0,0)) == "00:00:00"
@test string(Time(0,-1,0)) == "-00:01:00"
@test string(Time(0,0,-1)) == "-00:00:01"
@test string(Time(24,0,0)) == "24:00:00"

# Math
@test Time(1,23,45) + Time(-1,-23,-45) == Time(0)
@test Time(1,23,45) - Time(1,23,45) == Time(0)

# Time show function
t = Time(1,23,45)
buffer = IOBuffer()
print(buffer, t)
@test takebuf_string(buffer) == "01:23:45"
show(buffer, t)
@test takebuf_string(buffer) == "01:23:45"
