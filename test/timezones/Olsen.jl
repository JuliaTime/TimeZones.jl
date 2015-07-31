import TimeZones.Olsen: Time, hour, minute, second, as_seconds, hourminutesecond
import TimeZones.Olsen: parsedate
import Base.Dates: Hour, Minute, Second

# Time seconds constructor
t = Time(5025)
@test hour(t) == 1
@test minute(t) == 23
@test second(t) == 45
@test as_seconds(t) == 5025
@test hourminutesecond(t) == (1, 23, 45)

t = Time(-5025)
@test hour(t) == -1
@test minute(t) == -23
@test second(t) == -45
@test as_seconds(t) == -5025
@test hourminutesecond(t) == (-1, -23, -45)

t = Time(0,61,61)
@test t == Time(1,2,1)
@test as_seconds(t) == 3721

t = Time(1,-23,-45)
@test t == Time(0,36,15)
@test as_seconds(t) == 2175

# Time String constructor
@test Time("1") == Time(1,0,0)
@test Time("1:23") == Time(1,23,0)
@test Time("1:23:45") == Time(1,23,45)
@test Time("-1") == Time(-1,0,0)
@test Time("-1:23") == Time(-1,-23,0)
@test Time("-1:23:45") == Time(-1,-23,-45)
@test_throws Exception Time("1:-23:45")
@test_throws Exception Time("1:23:-45")
@test_throws Exception Time("1:23:45:67")

@test string(Time(1,23,45)) == "01:23:45"
@test string(Time(-1,-23,-45)) == "-01:23:45"
@test string(Time(0,0,0)) == "00:00:00"
@test string(Time(0,-1,0)) == "-00:01:00"
@test string(Time(0,0,-1)) == "-00:00:01"
@test string(Time(24,0,0)) == "24:00:00"

# Math
@test Time(1,23,45) + Time(-1,-23,-45) == Time(0)
@test Time(1,23,45) - Time(1,23,45) == Time(0)

# Variations of until dates
@test parsedate("1945") == (DateTime(1945), 0)
@test parsedate("1945 Aug") == (DateTime(1945,8), 0)
@test parsedate("1945 Aug 2") == (DateTime(1945,8,2), 0)
@test parsedate("1945 Aug 2 12") == (DateTime(1945,8,2,12), 0)  # Doesn't actually occur
@test parsedate("1945 Aug 2 12:34") == (DateTime(1945,8,2,12,34), 0)
@test parsedate("1945 Aug 2 12:34:56") == (DateTime(1945,8,2,12,34,56), 0)

# Make sure parsing can handle additional spaces.
@test parsedate("1945  Aug") == (DateTime(1945,8), 0)
@test parsedate("1945  Aug  2") == (DateTime(1945,8,2), 0)
@test parsedate("1945  Aug  2  12") == (DateTime(1945,8,2,12), 0)
@test parsedate("1945  Aug  2  12:34") == (DateTime(1945,8,2,12,34), 0)
@test parsedate("1945  Aug  2  12:34:56") == (DateTime(1945,8,2,12,34,56), 0)

# Explicit zone "local wall time"
@test_throws Exception parsedate("1945w")
@test_throws Exception parsedate("1945 Augw")
@test_throws Exception parsedate("1945 Aug 2w")
@test parsedate("1945 Aug 2 12w") == (DateTime(1945,8,2,12), 0)
@test parsedate("1945 Aug 2 12:34w") == (DateTime(1945,8,2,12,34), 0)
@test parsedate("1945 Aug 2 12:34:56w") == (DateTime(1945,8,2,12,34,56), 0)

# Explicit zone "UTC time"
@test_throws Exception parsedate("1945u")
@test_throws Exception parsedate("1945 Augu")
@test_throws Exception parsedate("1945 Aug 2u")
@test parsedate("1945 Aug 2 12u") == (DateTime(1945,8,2,12), 1)
@test parsedate("1945 Aug 2 12:34u") == (DateTime(1945,8,2,12,34), 1)
@test parsedate("1945 Aug 2 12:34:56u") == (DateTime(1945,8,2,12,34,56), 1)

# Explicit zone "standard time"
@test_throws Exception parsedate("1945s")
@test_throws Exception parsedate("1945 Augs")
@test_throws Exception parsedate("1945 Aug 2s")
@test parsedate("1945 Aug 2 12s") == (DateTime(1945,8,2,12), 2)
@test parsedate("1945 Aug 2 12:34s") == (DateTime(1945,8,2,12,34), 2)
@test parsedate("1945 Aug 2 12:34:56s") == (DateTime(1945,8,2,12,34,56), 2)

# Invalid zone
@test_throws Exception parsedate("1945 Aug 2 12:34i")

# Actual until date found in Zone "Pacific/Apia"
@test parsedate("2011 Dec 29 24:00") == (DateTime(2011,12,30), 0)
