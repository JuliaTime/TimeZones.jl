import TimeZones.Olsen: Time, hour, minute, second, toseconds, hourminutesecond
import TimeZones.Olsen: ZoneDict, RuleDict, zoneparse, ruleparse, resolve, parsedate
import Base.Dates: Hour, Minute, Second

# Time seconds constructor
t = Time(5025)
@test hour(t) == 1
@test minute(t) == 23
@test second(t) == 45
@test toseconds(t) == 5025
@test hourminutesecond(t) == (1, 23, 45)

t = Time(-5025)
@test hour(t) == -1
@test minute(t) == -23
@test second(t) == -45
@test toseconds(t) == -5025
@test hourminutesecond(t) == (-1, -23, -45)

t = Time(0,61,61)
@test t == Time(1,2,1)
@test toseconds(t) == 3721

t = Time(1,-23,-45)
@test t == Time(0,36,15)
@test toseconds(t) == 2175

# Time String constructor
@test Time("1") == Time(1,0,0)  # See Pacific/Apia rules for an example.
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
@test parsedate("1945") == (DateTime(1945), 'w')
@test parsedate("1945 Aug") == (DateTime(1945,8), 'w')
@test parsedate("1945 Aug 2") == (DateTime(1945,8,2), 'w')
@test parsedate("1945 Aug 2 12") == (DateTime(1945,8,2,12), 'w')  # Doesn't actually occur
@test parsedate("1945 Aug 2 12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945 Aug 2 12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Make sure parsing can handle additional spaces.
@test parsedate("1945  Aug") == (DateTime(1945,8), 'w')
@test parsedate("1945  Aug  2") == (DateTime(1945,8,2), 'w')
@test parsedate("1945  Aug  2  12") == (DateTime(1945,8,2,12), 'w')
@test parsedate("1945  Aug  2  12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945  Aug  2  12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Explicit zone "local wall time"
@test_throws Exception parsedate("1945w")
@test_throws Exception parsedate("1945 Augw")
@test_throws Exception parsedate("1945 Aug 2w")
@test parsedate("1945 Aug 2 12w") == (DateTime(1945,8,2,12), 'w')
@test parsedate("1945 Aug 2 12:34w") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945 Aug 2 12:34:56w") == (DateTime(1945,8,2,12,34,56), 'w')

# Explicit zone "UTC time"
@test_throws Exception parsedate("1945u")
@test_throws Exception parsedate("1945 Augu")
@test_throws Exception parsedate("1945 Aug 2u")
@test parsedate("1945 Aug 2 12u") == (DateTime(1945,8,2,12), 'u')
@test parsedate("1945 Aug 2 12:34u") == (DateTime(1945,8,2,12,34), 'u')
@test parsedate("1945 Aug 2 12:34:56u") == (DateTime(1945,8,2,12,34,56), 'u')

# Explicit zone "standard time"
@test_throws Exception parsedate("1945s")
@test_throws Exception parsedate("1945 Augs")
@test_throws Exception parsedate("1945 Aug 2s")
@test parsedate("1945 Aug 2 12s") == (DateTime(1945,8,2,12), 's')
@test parsedate("1945 Aug 2 12:34s") == (DateTime(1945,8,2,12,34), 's')
@test parsedate("1945 Aug 2 12:34:56s") == (DateTime(1945,8,2,12,34,56), 's')

# Invalid zone
@test_throws Exception parsedate("1945 Aug 2 12:34i")

# Actual until date found in Zone "Pacific/Apia"
@test parsedate("2011 Dec 29 24:00") == (DateTime(2011,12,30), 'w')


warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Europe/Warsaw timezone has a combination of factors that requires computing
# the abbreviation to be done in a specific way.
@test warsaw.transitions[1].zone.name == :LMT
@test warsaw.transitions[2].zone.name == :WMT
@test warsaw.transitions[3].zone.name == :CET   # Standard time
@test warsaw.transitions[4].zone.name == :CEST  # Daylight saving time

zone = Dict{String,FixedTimeZone}()
zone["LMT"] = FixedTimeZone("LMT", 5040, 0)
zone["WMT"] = FixedTimeZone("WMT", 5040, 0)
zone["CET"] = FixedTimeZone("CET", 3600, 0)
zone["CEST"] = FixedTimeZone("CEST", 3600, 3600)
zone["EET"] = FixedTimeZone("EET", 7200, 0)
zone["EEST"] = FixedTimeZone("EEST", 7200, 3600)

@test warsaw.transitions[1] == Transition(DateTime(1800,1,1), zone["LMT"])  # Really should be -Inf
@test warsaw.transitions[2] == Transition(DateTime(1879,12,31,22,36), zone["WMT"])
@test warsaw.transitions[3] == Transition(DateTime(1915,8,4,22,36), zone["CET"])
@test warsaw.transitions[4] == Transition(DateTime(1916,4,30,22,0), zone["CEST"])
@test warsaw.transitions[5] == Transition(DateTime(1916,9,30,23,0), zone["CET"])
@test warsaw.transitions[6] == Transition(DateTime(1917,4,16,1,0), zone["CEST"])
@test warsaw.transitions[7] == Transition(DateTime(1917,9,17,1,0), zone["CET"])
@test warsaw.transitions[8] == Transition(DateTime(1918,4,15,1,0), zone["CEST"])
@test warsaw.transitions[9] == Transition(DateTime(1918,9,16,1,0), zone["EET"]) #
@test warsaw.transitions[10] == Transition(DateTime(1919,4,15,0,0), zone["EEST"])
@test warsaw.transitions[11] == Transition(DateTime(1919,9,16,0,0), zone["EET"])
@test warsaw.transitions[12] == Transition(DateTime(1922,5,31,22,0), zone["CET"]) #
@test warsaw.transitions[13] == Transition(DateTime(1940,6,23,1,0), zone["CEST"])

@test warsaw.transitions[14] == Transition(DateTime(1942, 11, 2, 1, 0), zone["CET"])
@test warsaw.transitions[15] == Transition(DateTime(1943, 3, 29, 1, 0), zone["CEST"])
@test warsaw.transitions[16] == Transition(DateTime(1943, 10, 4, 1, 0), zone["CET"])
@test warsaw.transitions[17] == Transition(DateTime(1944, 4, 3, 1, 0), zone["CEST"]) #
@test warsaw.transitions[18] == Transition(DateTime(1944, 9, 30, 22, 0), zone["CEST"]) #


# Zone Pacific/Honolulu contains the following properties which make it good for testing:
# - Zone's contain save in rules field
# - Zone abbreviation redefined: HST

honolulu = resolve("Pacific/Honolulu", tzdata["northamerica"]...)

zone = Dict{String,FixedTimeZone}()
zone["LMT"] = FixedTimeZone("LMT", -37886, 0)
zone["HST"] = FixedTimeZone("HST", -37800, 0)
zone["HDT"] = FixedTimeZone("HDT", -37800, 3600)
zone["HST_NEW"] = FixedTimeZone("HST", -36000, 0)

@test honolulu.transitions[1] == Transition(DateTime(1800,1,1), zone["LMT"])
@test honolulu.transitions[2] == Transition(DateTime(1896,1,13,22,31,26), zone["HST"])
@test honolulu.transitions[3] == Transition(DateTime(1933,4,30,12,30), zone["HDT"])
@test honolulu.transitions[4] == Transition(DateTime(1933,5,21,21,30), zone["HST"])
@test honolulu.transitions[5] == Transition(DateTime(1942,2,9,12,30), zone["HDT"])
@test honolulu.transitions[6] == Transition(DateTime(1945,9,30,11,30), zone["HST"])
@test honolulu.transitions[7] == Transition(DateTime(1947,6,8,12,30), zone["HST_NEW"])


# Zone Pacific/Apia contains the following properties which make it good for testing:
# - Offset switch from -11:00 to 13:00
# - Rules interaction with a large negative offset
# - Rules interaction with a large positive offset
# - Includes a DateTime Julia could consider invalid: "2011 Dec 29 24:00"
# - Changed zone format while in a non-standard transition
# - Zone abbreviation redefined: LMT, WSST

apia = resolve("Pacific/Apia", tzdata["australasia"]...)

zone = Dict{String,FixedTimeZone}()
zone["LMT_OLD"] = FixedTimeZone("LMT", 45184, 0)
zone["LMT"] = FixedTimeZone("LMT", -41216, 0)
zone["WSST_OLD"] = FixedTimeZone("WSST", -41400, 0)
zone["SST"] = FixedTimeZone("SST", -39600, 0)
zone["SDT"] = FixedTimeZone("SDT", -39600, 3600)
zone["WSST"] = FixedTimeZone("WSST", 46800, 0)
zone["WSDT"] = FixedTimeZone("WSDT", 46800, 3600)

@test apia.transitions[1] == Transition(DateTime(1800,1,1), zone["LMT_OLD"])
@test apia.transitions[2] == Transition(DateTime(1879,7,4,11,26,56), zone["LMT"])
@test apia.transitions[3] == Transition(DateTime(1911,1,1,11,26,56), zone["WSST_OLD"])
@test apia.transitions[4] == Transition(DateTime(1950,1,1,11,30), zone["SST"])
@test apia.transitions[5] == Transition(DateTime(2010,9,26,11), zone["SDT"])
@test apia.transitions[6] == Transition(DateTime(2011,4,2,14), zone["SST"])
@test apia.transitions[7] == Transition(DateTime(2011,9,24,14), zone["SDT"])
@test apia.transitions[8] == Transition(DateTime(2011,12,30,10), zone["WSDT"])
@test apia.transitions[9] == Transition(DateTime(2012,3,31,14), zone["WSST"])
@test apia.transitions[10] == Transition(DateTime(2012,9,29,14), zone["WSDT"])


# Behaviour of mixing "RULES" as a String and as a Time. In reality this behaviour has never
# been observed.

# Manually generate zones and rules as if we had read them from a file.
zones = ZoneDict()
rules = RuleDict()

zones["Pacific/Test"] = [
    zoneparse("-10:00", "-", "TST-1", "1933 Apr 1 2:00s"),
    zoneparse("-10:00", "1:00", "TDT-2", "1933 Sep 1 2:00s"),
    zoneparse("-10:00", "Testing", "T%sT-3", "1934 Sep 1 3:00s"),
    zoneparse("-10:00", "1:00", "TDT-4", "1935 Sep 1 3:00s"),
    zoneparse("-10:00", "Testing", "T%sT-5", ""),
]
rules["Testing"] = [
    ruleparse("1934", "1935", "-", "Apr", "1", "3:00s", "1", "D"),
    ruleparse("1934", "1935", "-", "Sep", "1", "3:00s", "0", "S"),
]

test = resolve("Pacific/Test", zones, rules)

zone = Dict{String,FixedTimeZone}()
zone["TST-1"] = FixedTimeZone("TST-1", -36000, 0)
zone["TDT-2"] = FixedTimeZone("TDT-2", -36000, 3600)
zone["TST-3"] = FixedTimeZone("TST-3", -36000, 0)
zone["TDT-3"] = FixedTimeZone("TDT-3", -36000, 3600)
zone["TDT-4"] = FixedTimeZone("TDT-4", -36000, 3600)
zone["TST-5"] = FixedTimeZone("TST-5", -36000, 0)
zone["TDT-5"] = FixedTimeZone("TDT-5", -36000, 3600)

@test test.transitions[1] == Transition(DateTime(1800,1,1), zone["TST-1"])
@test test.transitions[2] == Transition(DateTime(1933,4,1,12), zone["TDT-2"]) # -09:00
@test test.transitions[3] == Transition(DateTime(1933,9,1,12), zone["TST-3"])
@test test.transitions[4] == Transition(DateTime(1934,4,1,13), zone["TDT-3"])
@test test.transitions[5] == Transition(DateTime(1934,9,1,13), zone["TDT-4"])
@test test.transitions[6] == Transition(DateTime(1935,9,1,13), zone["TST-5"])

# Note: Due to how I wrote the zones/rules a duplicate transition exists. The TimeZone code
# should be able to safely handle this but nothing should require duplicates.
@test test.transitions[6] == test.transitions[7]


# Make sure that we can deal with Links. Take note that the current implementation converts
# links into zones which makes it hard to explicitly test for a link. We expect that the
# following link exists:
#
# Link  Europe/Oslo  Arctic/Longyearbyen

# Make sure that that the link timezone was parsed.
zone_names = keys(tzdata["europe"][1])
@test "Arctic/Longyearbyen" in zone_names

oslo = resolve("Europe/Oslo", tzdata["europe"]...)
longyearbyen = resolve("Arctic/Longyearbyen", tzdata["europe"]...)

@test oslo.transitions == longyearbyen.transitions
