SUITE["parse"] = BenchmarkGroup()

# https://github.com/JuliaTime/TimeZones.jl/issues/25
function parse_dates(n)
    df = DateFormat("yyyymmddHH:MM:SS ZZZ")
    arr = Vector{ZonedDateTime}(undef, n)
    for (i, s) in enumerate(Iterators.repeated("2016060701:02:03 America/Toronto", n))
        arr[i] = ZonedDateTime(s,df)
    end
    return arr
end

SUITE["parse"]["issue#25"] = @benchmarkable parse_dates(1000)


SUITE["tryparsenext_fixedtz"] = BenchmarkGroup()
fixed_tz_strs = [
    "Z",
    "-06:00",
    "+06:00",
    "-0600",
    "+0600",
    "-06",
    "+06",
    "UTC",  # Invalid
]

for fixed_tz in fixed_tz_strs
    str = "2000-01-02T03:04:05" * fixed_tz
    SUITE["tryparsenext_fixedtz"][fixed_tz] = begin
        @benchmarkable TimeZones.tryparsenext_fixedtz($str, 20, $(lastindex(str)))
    end
end

SUITE["tryparsenext_tz"] = BenchmarkGroup()
tz_strs = [
    "UTC",
    "GMT",
    "EST",  # Invalid
    "America/Winnipeg",
    "America/Argentina/ComodRivadavia",
]

for tz in tz_strs
    str = "2000-01-02T03:04:05" * tz
    SUITE["tryparsenext_tz"][tz] = begin
        @benchmarkable TimeZones.tryparsenext_tz($str, 20, $(lastindex(str)))
    end
end

SUITE["parse"]["ISOZonedDateTimeFormat"] = begin
    str = "2000-01-02T03:04:05.006+0700"
    df = TimeZones.ISOZonedDateTimeFormat
    @benchmarkable parse(ZonedDateTime, $str, $df)
end

SUITE["parse"]["generic-string"] = begin
    str = GenericString("2018-01-01 00:00 UTC")
    df = dateformat"yyyy-mm-dd HH:MM ZZZ"
    @benchmarkable parse(ZonedDateTime, $str, $df)
end
