import TimeZones: FixedTimeZone, Transition

# # Create "test" check manually
# na, r = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "northamerica"));
# tz = z["America/Winnipeg"]

# test = TimeZones.Zoned(Dates.UTM(63492681600000))
# # Test DateTime construction by parts
# @test ZonedDateTime(DateTime(1918,10,27,0), tz) == ZonedDateTime(DateTime(1918,10,27,0), tz) ==
# @test Dates.DateTime(2013,1) == test
# @test Dates.DateTime(2013,1,1) == test
# @test Dates.DateTime(2013,1,1,0) == test
# @test Dates.DateTime(2013,1,1,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0,0) == test


# Note: Switch currently occurs are the wrong time.
europe_zones, europe_rules = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "europe"));
warsaw = TimeZones.Olsen.resolve("Europe/Warsaw", europe_zones, europe_rules)

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
@test warsaw.transitions[9] == Transition(DateTime(1918,9,16,1,0), zone["EET"])
@test warsaw.transitions[10] == Transition(DateTime(1919,4,15,0,0), zone["EEST"])
@test warsaw.transitions[11] == Transition(DateTime(1919,9,16,0,0), zone["EET"])
@test warsaw.transitions[12] == Transition(DateTime(1922,5,31,22,0), zone["CET"])
@test warsaw.transitions[13] == Transition(DateTime(1940,6,23,1,0), zone["CEST"])






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
