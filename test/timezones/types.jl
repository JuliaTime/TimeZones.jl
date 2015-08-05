import TimeZones: TimeZone, FixedTimeZone, Transition
import TimeZones.Olsen: tzparse, resolve, ZoneDict, RuleDict

# Note: It is possible the testcases could fail due to changes to the TZ database. If this
# occurs we may want to keep a static TZ database around for testing purposes. These test
# cases were generated from a TZ database last modified 2015/07/06.

# For testing we'll reparse the tzdata every time to simplify development.
tzdata_dir = joinpath(dirname(@__FILE__), "..", "..", "deps", "tzdata")

tzdata = Dict{String,Tuple{ZoneDict,RuleDict}}()
for name in ("australasia", "europe", "northamerica")
    tzdata[name] = tzparse(joinpath(tzdata_dir, name))
end

# test = TimeZones.Zoned(Dates.UTM(63492681600000))
# # Test DateTime construction by parts
# @test ZonedDateTime(DateTime(1918,10,27,0), tz) == ZonedDateTime(DateTime(1918,10,27,0), tz) ==
# @test Dates.DateTime(2013,1) == test
# @test Dates.DateTime(2013,1,1) == test
# @test Dates.DateTime(2013,1,1,0) == test
# @test Dates.DateTime(2013,1,1,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0,0) == test

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Europe/Warsaw timezone has a combination of factors that requires computing
# the abbreviation to be done in a specific way.
@test warsaw.transitions[1].zone.name == :LMT
@test warsaw.transitions[2].zone.name == :WMT
@test warsaw.transitions[3].zone.name == :CET   # Standard time
@test warsaw.transitions[4].zone.name == :CEST  # Daylight saving time

zone = Dict{String,FixedTimeZone}()
zone["LMT"] = TimeZones.DaylightSavingTimeZone("LMT", 5040, 0)
zone["WMT"] = TimeZones.DaylightSavingTimeZone("WMT", 5040, 0)
zone["CET"] = TimeZones.DaylightSavingTimeZone("CET", 3600, 0)
zone["CEST"] = TimeZones.DaylightSavingTimeZone("CEST", 3600, 3600)
zone["EET"] = TimeZones.DaylightSavingTimeZone("EET", 7200, 0)
zone["EEST"] = TimeZones.DaylightSavingTimeZone("EEST", 7200, 3600)

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
zone["LMT"] = TimeZones.DaylightSavingTimeZone("LMT", -37886, 0)
zone["HST"] = TimeZones.DaylightSavingTimeZone("HST", -37800, 0)
zone["HDT"] = TimeZones.DaylightSavingTimeZone("HDT", -37800, 3600)
zone["HST_NEW"] = TimeZones.DaylightSavingTimeZone("HST", -36000, 0)

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
zone["LMT_OLD"] = TimeZones.DaylightSavingTimeZone("LMT", 45184, 0)
zone["LMT"] = TimeZones.DaylightSavingTimeZone("LMT", -41216, 0)
zone["WSST_OLD"] = TimeZones.DaylightSavingTimeZone("WSST", -41400, 0)
zone["SST"] = TimeZones.DaylightSavingTimeZone("SST", -39600, 0)
zone["SDT"] = TimeZones.DaylightSavingTimeZone("SDT", -39600, 3600)
zone["WSST"] = TimeZones.DaylightSavingTimeZone("WSST", 46800, 0)
zone["WSDT"] = TimeZones.DaylightSavingTimeZone("WSDT", 46800, 3600)

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



# TODO: Mixed Rules string and save? Made up:
# -10:30    1:00    HDT 1933 May 21 12:00
# -10:30    Pacific H%sT 1933 May 21 12:00


# import Base.Dates: year
# for t in warsaw.transitions
#     if year(t.utc_datetime) < 1950
#         println(t)
#     end
# end

# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw)
# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, true)
# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, false)
# @test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 1).zone.name == :EET
# @test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 2).zone.name == :CET


# na_zones, na_rules = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "northamerica"));
# winnipeg = TimeZones.Olsen.resolve("America/Winnipeg", na_zones, na_rules)
# @test ZonedDateTime(DateTime(1945,8,14,17), winnipeg).zone.name == :CWT
# @test ZonedDateTime(DateTime(1945,8,14,18), winnipeg).zone.name == :CPT
