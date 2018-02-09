using TimeZones.TZData: TimeOffset, value, hour, minute, second, hourminutesecond

# Time seconds constructor
t = TimeOffset(5025)
@test hour(t) == 1
@test minute(t) == 23
@test second(t) == 45
@test value(t) == 5025
@test hourminutesecond(t) == (1, 23, 45)

t = TimeOffset(-5025)
@test hour(t) == -1
@test minute(t) == -23
@test second(t) == -45
@test value(t) == -5025
@test hourminutesecond(t) == (-1, -23, -45)

t = TimeOffset(0,61,61)
@test t == TimeOffset(1,2,1)
@test value(t) == 3721

t = TimeOffset(1,-23,-45)
@test t == TimeOffset(0,36,15)
@test value(t) == 2175

# TimeOffset String constructor
@test TimeOffset("1") == TimeOffset(1,0,0)  # See Pacific/Apia rules for an example.
@test TimeOffset("1:23") == TimeOffset(1,23,0)
@test TimeOffset("1:23:45") == TimeOffset(1,23,45)
@test TimeOffset("-1") == TimeOffset(-1,0,0)
@test TimeOffset("-1:23") == TimeOffset(-1,-23,0)
@test TimeOffset("-1:23:45") == TimeOffset(-1,-23,-45)
@test_throws ArgumentError TimeOffset("1:-23:45")
@test_throws ArgumentError TimeOffset("1:23:-45")
@test_throws ArgumentError TimeOffset("1:23:45:67")

@test string(TimeOffset(1,23,45)) == "01:23:45"
@test string(TimeOffset(-1,-23,-45)) == "-01:23:45"
@test string(TimeOffset(0,0,0)) == "00:00:00"
@test string(TimeOffset(0,-1,0)) == "-00:01:00"
@test string(TimeOffset(0,0,-1)) == "-00:00:01"
@test string(TimeOffset(24,0,0)) == "24:00:00"

# Math
@test TimeOffset(1,23,45) + TimeOffset(-1,-23,-45) == TimeOffset(0)
@test TimeOffset(1,23,45) - TimeOffset(1,23,45) == TimeOffset(0)

# TimeOffset show function
t = TimeOffset(1,23,45)
@test sprint(print, t) == "01:23:45"
@test sprint(show, t) == "01:23:45"
