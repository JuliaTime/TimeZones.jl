using TimeZones: Transition
using TimeZones.TZData: TZSource, Zone, Rule, compile, parse_date, order_rules,
    tryparse_dayofmonth_function
using Dates: Hour, Minute, Second, DateTime, Date

@testset "tryparse_dayofmonth_function" begin
    # Using 2019/03 as the test month. Results can be validated by viewing a calendar:
    # https://www.timeanddate.com/calendar/monthly.html?year=2019&month=3&country=1
    @test tryparse_dayofmonth_function("lastSun")(2019, 3) == Date(2019, 3, 31)
    @test tryparse_dayofmonth_function("lastThu")(2019, 3) == Date(2019, 3, 28)
    @test tryparse_dayofmonth_function("Sun>=1")(2019, 3) == Date(2019, 3, 3)
    @test tryparse_dayofmonth_function("Sun>=8")(2019, 3) == Date(2019, 3, 10)
    @test tryparse_dayofmonth_function("Fri<=1")(2019, 4) == Date(2019, 3, 29)
    @test tryparse_dayofmonth_function("Wed>=28")(2019, 2) == Date(2019, 3, 6)
    @test tryparse_dayofmonth_function("15")(2019, 3) == Date(2019, 3, 15)
end

### parse_date ###

# Variations of until dates
@test parse_date("1945") == (DateTime(1945), 'w')
@test parse_date("1945 Aug") == (DateTime(1945,8), 'w')
@test parse_date("1945 Aug 2") == (DateTime(1945,8,2), 'w')
@test parse_date("1945 Aug 2 12") == (DateTime(1945,8,2,12), 'w')  # Doesn't actually occur
@test parse_date("1945 Aug 2 12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parse_date("1945 Aug 2 12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Make sure parsing can handle additional spaces.
@test parse_date("1945  Aug") == (DateTime(1945,8), 'w')
@test parse_date("1945  Aug  2") == (DateTime(1945,8,2), 'w')
@test parse_date("1945  Aug  2  12") == (DateTime(1945,8,2,12), 'w')
@test parse_date("1945  Aug  2  12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parse_date("1945  Aug  2  12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Rollover at the end of the year
@test parse_date("2017 Dec Sun>=31 24:00") == (DateTime(2018,1,1), 'w')

# Explicit zone "local wall time"
@test_throws ArgumentError parse_date("1945w")
@test_throws Exception parse_date("1945 Augw")  # Julia <=0.6 KeyError, 0.6 ArgumentError
@test_throws ArgumentError parse_date("1945 Aug 2w")
@test parse_date("1945 Aug 2 12w") == (DateTime(1945,8,2,12), 'w')
@test parse_date("1945 Aug 2 12:34w") == (DateTime(1945,8,2,12,34), 'w')
@test parse_date("1945 Aug 2 12:34:56w") == (DateTime(1945,8,2,12,34,56), 'w')

# Explicit zone "UTC time"
@test_throws ArgumentError parse_date("1945u")
@test_throws Exception parse_date("1945 Augu")
@test_throws ArgumentError parse_date("1945 Aug 2u")
@test parse_date("1945 Aug 2 12u") == (DateTime(1945,8,2,12), 'u')
@test parse_date("1945 Aug 2 12:34u") == (DateTime(1945,8,2,12,34), 'u')
@test parse_date("1945 Aug 2 12:34:56u") == (DateTime(1945,8,2,12,34,56), 'u')

# Explicit zone "standard time"
@test_throws ArgumentError parse_date("1945s")
@test_throws Exception parse_date("1945 Augs")
@test_throws ArgumentError parse_date("1945 Aug 2s")
@test parse_date("1945 Aug 2 12s") == (DateTime(1945,8,2,12), 's')
@test parse_date("1945 Aug 2 12:34s") == (DateTime(1945,8,2,12,34), 's')
@test parse_date("1945 Aug 2 12:34:56s") == (DateTime(1945,8,2,12,34,56), 's')

# Invalid zone
@test_throws ArgumentError parse_date("1945 Aug 2 12:34i")

# Actual dates found tzdata files
@test parse_date("2011 Dec 29 24:00") == (DateTime(2011,12,30), 'w')      # Pacific/Apia (2014f)
@test parse_date("1945 Sep 30 24:00") == (DateTime(1945,10,1), 'w')       # Asia/Macau (2018f)
@test parse_date("2019 Mar Sun>=8 3:00") == (DateTime(2019,3,10,3), 'w')  # America/Metlakatla (2018h)
@test parse_date("2006 Apr Fri<=1 2:00") == (DateTime(2006,3,31,2), 'w')  # Asia/Jerusalem (2019b)

@testset "parse Rule" begin
    # tzdata 2024b introduced the use of a non-three letter month: April
    # https://github.com/JuliaTime/TimeZones.jl/issues/471
    rule = parse(Rule, "1931    only    -   April   30  0:00    1:00    D")
    @test rule.from == 1931
    @test rule.to == 1931
    @test rule.month == 4
    @test rule.on(rule.from, rule.month) == Date(1931, 4, 30)
    @test rule.at == TimeOffset(0)
    @test rule.at_flag == 'w'
    @test rule.save == TimeOffset(3600)
    @test rule.letter == "D"
end

### order_rules ###

# Rule    Poland  1918    1919    -   Sep 16  2:00s   0       -
# Rule    Poland  1919    only    -   Apr 15  2:00s   1:00    S
# Rule    Poland  1944    only    -   Apr  3  2:00s   1:00    S
rule_a = parse(Rule, "1918    1919    -   Sep 16  2:00s   0       -")
rule_b = parse(Rule, "1919    only    -   Apr 15  2:00s   1:00    S")
rule_c = parse(Rule, "1944    only    -   Apr  3  2:00s   1:00    S")

# Note: Alternatively we could be using `permutations` here.
for rules in ([rule_a, rule_b, rule_c], [rule_c, rule_b, rule_a], [rule_a, rule_c, rule_b])
    dates, ordered = order_rules(rules)

    @test dates == [Date(1918, 9, 16), Date(1919, 4, 15), Date(1919, 9, 16), Date(1944, 4, 3)]
    @test ordered == [rule_a, rule_b, rule_a, rule_c]
end

# ignore rules starting after the cutoff
dates, ordered = order_rules([rule_a, rule_b, rule_c], max_year=1940)
@test dates == [Date(1918, 9, 16), Date(1919, 4, 15), Date(1919, 9, 16)]
@test ordered == [rule_a, rule_b, rule_a]

# truncate rules ending after the cutoff
rule_pre     = parse(Rule, "1999    only    -   Jun 7  2:00s   0   P")
rule_overlap = parse(Rule, "1999    2001    -   Jan 1  0:00s   0   -")
rule_endless = parse(Rule, "1993    max     -   Feb 2  6:00s   0   G")
rule_post    = parse(Rule, "2002    only    -   Jan 1  0:00s   0   IP")

dates, ordered = order_rules([rule_post, rule_endless, rule_overlap, rule_pre], max_year=2000)
@test dates == [
    Date(1993, 2, 2),
    Date(1994, 2, 2),
    Date(1995, 2, 2),
    Date(1996, 2, 2),
    Date(1997, 2, 2),
    Date(1998, 2, 2),
    Date(1999, 1, 1),
    Date(1999, 2, 2),
    Date(1999, 6, 7),
    Date(2000, 1, 1),
    Date(2000, 2, 2),
]
# Equality check based on reference
@test ordered == [
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    rule_overlap,
    rule_endless,
    rule_pre,
    rule_overlap,
    rule_endless,
]

@testset "compile" begin
    @testset "Europe/Warsaw" begin
        tz = first(compile("Europe/Warsaw", tzdata["europe"]))

        # Europe/Warsaw time zone has a combination of factors that requires computing
        # the abbreviation to be done in a specific way.
        @test tz.transitions[1].zone.name == "LMT"
        @test tz.transitions[2].zone.name == "WMT"
        @test tz.transitions[3].zone.name == "CET"   # Standard time
        @test tz.transitions[4].zone.name == "CEST"  # Daylight saving time
        @test issorted(tz.transitions)

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["LMT"] = FixedTimeZone("LMT", 5040, 0)
        zone["WMT"] = FixedTimeZone("WMT", 5040, 0)
        zone["CET"] = FixedTimeZone("CET", 3600, 0)
        zone["CEST"] = FixedTimeZone("CEST", 3600, 3600)
        zone["EET"] = FixedTimeZone("EET", 7200, 0)
        zone["EEST"] = FixedTimeZone("EEST", 7200, 3600)

        @test tz.transitions[1] == Transition(typemin(DateTime), zone["LMT"])  # Ideally -Inf
        @test tz.transitions[2] == Transition(DateTime(1879,12,31,22,36), zone["WMT"])
        @test tz.transitions[3] == Transition(DateTime(1915,8,4,22,36), zone["CET"])
        @test tz.transitions[4] == Transition(DateTime(1916,4,30,22,0), zone["CEST"])
        @test tz.transitions[5] == Transition(DateTime(1916,9,30,23,0), zone["CET"])
        @test tz.transitions[6] == Transition(DateTime(1917,4,16,1,0), zone["CEST"])
        @test tz.transitions[7] == Transition(DateTime(1917,9,17,1,0), zone["CET"])
        @test tz.transitions[8] == Transition(DateTime(1918,4,15,1,0), zone["CEST"])
        @test tz.transitions[9] == Transition(DateTime(1918,9,16,1,0), zone["EET"]) #
        @test tz.transitions[10] == Transition(DateTime(1919,4,15,0,0), zone["EEST"])
        @test tz.transitions[11] == Transition(DateTime(1919,9,16,0,0), zone["EET"])
        @test tz.transitions[12] == Transition(DateTime(1922,5,31,22,0), zone["CET"]) #
        @test tz.transitions[13] == Transition(DateTime(1940,6,23,1,0), zone["CEST"])

        @test tz.transitions[14] == Transition(DateTime(1942,11,2,1,0), zone["CET"])
        @test tz.transitions[15] == Transition(DateTime(1943,3,29,1,0), zone["CEST"])
        @test tz.transitions[16] == Transition(DateTime(1943,10,4,1,0), zone["CET"])
        @test tz.transitions[17] == Transition(DateTime(1944,4,3,1,0), zone["CEST"])
        @test tz.transitions[18] == Transition(DateTime(1944,10,4,0,0), zone["CET"])
    end

    # Zone Pacific/Honolulu contains the following properties which make it good for testing:
    # - Zone's contain save in rules field
    # - Zone abbreviation redefined: HST
    # - Is not cutoff
    @testset "Pacific/Honolulu" begin
        tz = first(compile("Pacific/Honolulu", tzdata["northamerica"]))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["LMT"] = FixedTimeZone("LMT", -37886, 0)
        zone["HST"] = FixedTimeZone("HST", -37800, 0)
        zone["HDT"] = FixedTimeZone("HDT", -37800, 3600)
        zone["HST_NEW"] = FixedTimeZone("HST", -36000, 0)

        @test tz.transitions[1] == Transition(typemin(DateTime), zone["LMT"])
        @test tz.transitions[2] == Transition(DateTime(1896,1,13,22,31,26), zone["HST"])
        @test tz.transitions[3] == Transition(DateTime(1933,4,30,12,30), zone["HDT"])
        @test tz.transitions[4] == Transition(DateTime(1933,5,21,21,30), zone["HST"])
        @test tz.transitions[5] == Transition(DateTime(1942,2,9,12,30), zone["HDT"])
        @test tz.transitions[6] == Transition(DateTime(1945,9,30,11,30), zone["HST"])
        @test tz.transitions[7] == Transition(DateTime(1947,6,8,12,30), zone["HST_NEW"])

        @test length(tz.transitions) == 7
        @test tz.cutoff === nothing
    end

    # Zone Pacific/Apia contains the following properties which make it good for testing:
    # - Offset switch from -11:00 to 13:00
    # - Rules interaction with a large negative offset
    # - Rules interaction with a large positive offset
    # - Includes a DateTime Julia could consider invalid: "2011 Dec 29 24:00"
    # - Changed zone format while in a non-standard transition
    # - Zone abbreviation redefined: LMT, WSST
    @testset "Pacific/Apia" begin
        tz = first(compile("Pacific/Apia", tzdata["australasia"]))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["LMT_OLD"] = FixedTimeZone("LMT", 45184, 0)
        zone["LMT"] = FixedTimeZone("LMT", -41216, 0)
        zone["WSST_OLD"] = FixedTimeZone("WSST", -41400, 0)
        zone["SST"] = FixedTimeZone("SST", -39600, 0)
        zone["SDT"] = FixedTimeZone("SDT", -39600, 3600)
        zone["WSST"] = FixedTimeZone("WSST", 46800, 0)
        zone["WSDT"] = FixedTimeZone("WSDT", 46800, 3600)

        @test tz.transitions[1] == Transition(typemin(DateTime), zone["LMT_OLD"])
        @test tz.transitions[2] == Transition(DateTime(1879,7,4,11,26,56), zone["LMT"])
        @test tz.transitions[3] == Transition(DateTime(1911,1,1,11,26,56), zone["WSST_OLD"])
        @test tz.transitions[4] == Transition(DateTime(1950,1,1,11,30), zone["SST"])
        @test tz.transitions[5] == Transition(DateTime(2010,9,26,11), zone["SDT"])
        @test tz.transitions[6] == Transition(DateTime(2011,4,2,14), zone["SST"])
        @test tz.transitions[7] == Transition(DateTime(2011,9,24,14), zone["SDT"])
        @test tz.transitions[8] == Transition(DateTime(2011,12,30,10), zone["WSDT"])
        @test tz.transitions[9] == Transition(DateTime(2012,3,31,14), zone["WSST"])
        @test tz.transitions[10] == Transition(DateTime(2012,9,29,14), zone["WSDT"])
    end


    # Zone Europe/Madrid contains the following properties which make it good for testing:
    # - Observed midsummer time
    # - End of midsummer time also switches both the UTC offset and the saving time
    # - In 1979-01-01 switches from "Spain" to "EU" rules which could create a redundant entry
    @testset "Europe/Madrid" begin
        tz = first(compile("Europe/Madrid", tzdata["europe"]))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["WET"] = FixedTimeZone("WET", 0, 0)
        zone["WEST"] = FixedTimeZone("WEST", 0, 3600)
        zone["WEMT"] = FixedTimeZone("WEMT", 0, 7200)
        zone["CET"] = FixedTimeZone("CET", 3600, 0)
        zone["CEST"] = FixedTimeZone("CEST", 3600, 3600)

        @test tz.transitions[23] == Transition(DateTime(1939,4,15,23), zone["WEST"])
        @test tz.transitions[24] == Transition(DateTime(1939,10,7,23), zone["WET"])
        @test tz.transitions[25] == Transition(DateTime(1940,3,16,23), zone["WEST"])
        @test tz.transitions[26] == Transition(DateTime(1942,5,2,22), zone["WEMT"])

        @test tz.transitions[33] == Transition(DateTime(1945,9,29,23), zone["WEST"])
        @test tz.transitions[34] == Transition(DateTime(1946,4,13,22), zone["WEMT"])
        @test tz.transitions[35] == Transition(DateTime(1946,9,29,22), zone["CET"])
        @test tz.transitions[36] == Transition(DateTime(1949,4,30,22), zone["CEST"])

        # Redundant transition would be around 1979-01-01T00:00:00 as CET
        @test tz.transitions[47] == Transition(DateTime(1978,9,30,23), zone["CET"])
        @test tz.transitions[48] == Transition(DateTime(1979,4,1,1), zone["CEST"])
    end

    # Zone America/Anchorage contains the following properties which make it good for testing:
    # - Uses a format containing a slash which indicates the abbreviations for STD/DST
    #   Alternatives include: Europe/London, Europe/Dublin, and Europe/Moscow.
    # - Observed war/peace time
    @testset "America/Anchorage" begin
        tz = first(compile("America/Anchorage", tzdata["northamerica"]))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["CAT"] = FixedTimeZone("CAT", -36000, 0)
        zone["CAWT"] = FixedTimeZone("CAWT", -36000, 3600)
        zone["CAPT"] = FixedTimeZone("CAPT", -36000, 3600)
        zone["AHST"] = FixedTimeZone("AHST", -36000, 0)
        zone["AHDT"] = FixedTimeZone("AHDT", -36000, 3600)

        @test tz.transitions[3] == Transition(DateTime(1900,8,20,21,59,36), zone["CAT"])
        @test tz.transitions[4] == Transition(DateTime(1942,2,9,12), zone["CAWT"])
        @test tz.transitions[5] == Transition(DateTime(1945,8,14,23), zone["CAPT"])
        @test tz.transitions[6] == Transition(DateTime(1945,9,30,11), zone["CAT"])
        @test tz.transitions[7] == Transition(DateTime(1967,4,1,10), zone["AHST"])
        @test tz.transitions[8] == Transition(DateTime(1969,4,27,12), zone["AHDT"])
    end

    # Zone Europe/Ulyanovsk contains the following properties which make it good for testing:
    # - With the exception of LMT all Zone and Rule abbreviations are UTC offsets which should
    #   be treated as NULL.
    @testset "Europe/Ulyanovsk" begin
        ulyanovsk = first(compile("Europe/Ulyanovsk", tzdata["europe"]))
        @test all(t -> string(t.zone.name) == "", ulyanovsk.transitions[2:end])
    end

    # Fake Zone Pacific/Cutoff contains the following properties which make it good for testing:
    # - Having a single transition on the first year allows us to test the special case where we
    #   need to include a cutoff while only having a single transition
    # - Having no rules ensures that cutoff is calculated correctly with only zones
    @testset "Pacific/Cutoff (Fake)" begin
        # Manually generate zones and rules as if we had read them from a file.
        zones = Dict{String,Vector{Zone}}()
        rules = Dict{String,Vector{Rule}}()
        links = Dict{String,String}()

        zones["Pacific/Cutoff"] = [
            parse(Zone, "-10:00    -   CUT-1   1933 Apr 1 2:00s"),
            parse(Zone, "-11:00    -   CUT-2"),
        ]
        tz_source = TZSource(zones, rules, links)

        tz = first(compile("Pacific/Cutoff", tz_source))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["CUT-1"] = FixedTimeZone("CUT-1", -36000)
        zone["CUT-2"] = FixedTimeZone("CUT-2", -39600)

        @test tz.transitions[1] == Transition(typemin(DateTime), zone["CUT-1"])
        @test tz.transitions[2] == Transition(DateTime(1933,4,1,12), zone["CUT-2"])
        @test tz.cutoff === nothing

        tz = first(compile("Pacific/Cutoff", tz_source, max_year=1900))

        # Normally compiled TimeZones with a single transition are returned as a
        # FixedTimeZone except when a cutoff is included.
        @test isa(tz, VariableTimeZone)
        @test length(tz.transitions) == 1
        @test tz.cutoff == DateTime(1933,4,1,12)
    end

    # Behaviour of mixing "RULES" as a String and as a Time. In reality this behaviour has never
    # been observed.
    @testset "Pacific/Test (Fake)" begin
        # Manually generate zones and rules as if we had read them from a file.
        zones = Dict{String,Vector{Zone}}()
        rules = Dict{String,Vector{Rule}}()
        links = Dict{String,String}()

        zones["Pacific/Test"] = [
            parse(Zone, "-10:00      -         TST-1    1933 Apr 1 2:00s"),
            parse(Zone, "-10:00      1:00      TDT-2    1933 Sep 1 2:00s"),
            parse(Zone, "-10:00      Testing   T%sT-3   1934 Sep 1 3:00s"),
            parse(Zone, "-10:00      1:00      TDT-4    1935 Sep 1 3:00s"),
            parse(Zone, "-10:00      Testing   T%sT-5"),
        ]
        rules["Testing"] = [
            parse(Rule, "1934  1935  -         Apr 1    3:00s   1   D"),
            parse(Rule, "1934  1935  -         Sep 1    3:00s   0   S"),
        ]
        tz_source = TZSource(zones, rules, links)

        tz = first(compile("Pacific/Test", tz_source))

        zone = Dict{AbstractString,FixedTimeZone}()
        zone["TST-1"] = FixedTimeZone("TST-1", -36000, 0)
        zone["TDT-2"] = FixedTimeZone("TDT-2", -36000, 3600)
        zone["TST-3"] = FixedTimeZone("TST-3", -36000, 0)
        zone["TDT-3"] = FixedTimeZone("TDT-3", -36000, 3600)
        zone["TDT-4"] = FixedTimeZone("TDT-4", -36000, 3600)
        zone["TST-5"] = FixedTimeZone("TST-5", -36000, 0)
        zone["TDT-5"] = FixedTimeZone("TDT-5", -36000, 3600)

        @test tz.transitions[1] == Transition(typemin(DateTime), zone["TST-1"])
        @test tz.transitions[2] == Transition(DateTime(1933,4,1,12), zone["TDT-2"]) # -09:00
        @test tz.transitions[3] == Transition(DateTime(1933,9,1,12), zone["TST-3"])
        @test tz.transitions[4] == Transition(DateTime(1934,4,1,13), zone["TDT-3"])
        @test tz.transitions[5] == Transition(DateTime(1934,9,1,13), zone["TDT-4"])
        @test tz.transitions[6] == Transition(DateTime(1935,9,1,13), zone["TST-5"])

        # Note: Due to how the the zones/rules were written a redundant transition could be created
        # such that `test.transitions[6] == test.transitions[7]`. The TimeZone code can safely
        # handle redundant transitions but ideally they should be eliminated.
        @test length(tz.transitions) == 6
    end

    # Make sure that we can deal with Links. Take note that the current implementation converts
    # links into zones which makes it hard to explicitly test for a link. We expect that the
    # following link exists:
    #
    # Link  Europe/Oslo  Arctic/Longyearbyen
    @testset "Link" begin
        # Make sure that that the link time zone was parsed.
        @test !haskey(tzdata["europe"].zones, "Arctic/Longyearbyen")
        @test  haskey(tzdata["europe"].links, "Arctic/Longyearbyen")
        @test tzdata["europe"].links["Arctic/Longyearbyen"] == "Europe/Oslo"

        oslo = first(compile("Europe/Oslo", tzdata["europe"]))
        longyearbyen = first(compile("Arctic/Longyearbyen", tzdata["europe"]))

        @test longyearbyen.name != oslo.name
        @test longyearbyen.transitions == oslo.transitions
        @test longyearbyen.cutoff == oslo.cutoff
    end

    # Zones that don't include multiple lines and no rules should be treated as a FixedTimeZone.
    @testset "FixedTimeZone" begin
        tz = first(compile("MST", tzdata["northamerica"]))
        @test isa(tz, FixedTimeZone)
    end
end
