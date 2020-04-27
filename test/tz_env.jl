# TimeZones.jl supports parsing a direct time zone specification as provided by tzset(3).
# Unfortunately, different platforms only follow parts of the specification which results in
# differences from platform-to-platform.
#
# TimeZones.jl follows the tzset(3) specification and avoids supporting additional features
# which may not be present on all platforms. As the platform specific functionality only
# really deals with corner cases which are not required by any actual time zone definition
# supporting for these features is purely academic.
#
# Here are some examples of the platform specific differences. Under macOS time zone offset
# only supports hours under ±7 days (167 hours) and hours beyond this range result in
# falling back to UTC:
#
# ```bash
# $ TZ="FOO-0" date -r 0
# Thu  1 Jan 1970 00:00:00 UTC
#
# $ TZ="FOO-167" date -r 0
# Wed  7 Jan 1970 23:00:00 FOO
#
# $ TZ="FOO-168" date -r 0
# Thu  1 Jan 1970 00:00:00 UTC
# ```
#
# Under Linux the time zone offset only supports hours up to ±1 day (24 hours) and hours
# beyond that are clamped to exactly 24 hours.
#
# ```bash
# $ TZ="FOO" date --date @0
# Thu Jan  1 00:00:00 FOO 1970
#
# $ TZ="FOO-24" date --date @0
# Fri Jan  2 00:00:00 FOO 1970
#
# $ TZ="FOO-25" date --date @0
# Fri Jan  2 00:00:00 FOO 1970
# ```
#
# Under macOS the transition time only supports hours under ±7 days (167 hours) and hours
# beyond this range result in falling back to UTC:
#
# ```bash
# $ TZ="FOO-1BAR-2,1/0,1/167" date -r 1609455600
# Fri  1 Jan 2021 00:00:00 FOO
#
# $ TZ="FOO-1BAR-2,1/0,1/168" date -r 1609455600
# Thu 31 Dec 2020 23:00:00 UTC
# ```
#
# Under Linux the transition time appears to have no limit:
#
# ```bash
# $ TZ="FOO-1BAR-2,1/0,1/8761" date --date @1609455600
# Fri Jan  1 00:00:00 FOO 2021
# $ TZ="FOO-1BAR-2,1/0,1/8762" date --date @1609455600
# Fri Jan  1 01:00:00 BAR 2021
# ```

# Below is a listing of corner cases with TZ interpretation and behaviours on various
# platforms. We have tests cases for these assist in discovering any behaviour changes that
# may occur over time or when encountering a new platform.
#
# TZ=ABC
# - tzset(3): Invalid, an standard offset is required
# - Linux: Alternate way of writing `TZ=ABC+0`
# - macOS: Invalid, falls back to: `TZ=UTC`
#
# TZ="<>+1"
# - tzset(3): Invalid, an offset name must be at least three characters
# - Linux: Invalid, falls back to: `TZ="<>0"`
# - macOS: Supported
#
# TZ=A1
# - tzset(3): Invalid, an offset name must be at least three characters
# - Linux: Invalid, falls back to: `TZ="<>0"`
# - macOS: Supported
#
# TZ="<αβc>1"
# - tzset(3): Undefined behaviour, unicode support isn't mentioned
# - Linux: Invalid, falls back to: `TZ="<>0"`
# - macOS: Mostly supported, equivalent of `TZ="<____c>1"`
#
# TZ=ABC25
# - tzset(3): Invalid, offset hours must be between 0 and 24.
# - Linux: Clamped to ±24 hours and equivalent to `TZ=ABC24`
# - macOS: Supported
#
# TZ=ABC-168
# - tzset(3): Invalid, offset hours must be between 0 and 24.
# - Linux: Clamped to ±24 hours and equivalent to `TZ=ABC-24`
# - macOS: Invalid, only supports ±167 hours and falls back to: `TZ=UTC`
#
# TZ=FOO0BAR0,M1.5.6,1
# - tzset(3): Supported, DST transition occurs on the last Saturday in January. For
#   January's that only contain 4 Saturdays this is equivalent to M1.4.6.
# - Linux: Supported
# - macOS: Supported
#
# TZ=FOO0BAR0,365,1
# - tzset(3): Undefined behaviour, using a zero-based Julian day of 365 on a non-leap year
#   would be the first day of the following year.
# - Linux: Clamped non-leap year transition to first instant of the following year.
# - macOS: Supported
#
# TZ=FOO-1BAR-2,1/0,1/8762
# - tzset(3): Undefined behaviour, no specification is provided for transition time
# - Linux: Supported
# - macOS: Invalid, falls back to `TZ=UTC`
#
# TZ=FOO0BAR01/+1,2/-1
# - tzset(3): Undefined behaviour, no specification is provided for +/- time
# - Linux: Supported
# - macOS: Invalid, falls back to `TZ=UTC`

function tzdate(dt::DateTime, tz::AbstractString)
    iszero(millisecond(dt)) || throw(ArgumentError("Milliseconds not supported"))
    str = Dates.format(dt, dateformat"yyyy-mm-dd\THH:MM:SS")
    out_format = "%Y-%m-%dT%H:%M:%S%z (%Z)"
    withenv("TZ" => tz) do
        if Sys.isapple()
            readchomp(`date -j -f %Y-%m-%dT%H:%M:%S $str +$out_format`)
        elseif Sys.isunix()
            readchomp(`date --date=$str +$out_format`)
        else
            error("Unsupported platform")
        end
    end
end

@testset "System TZ behaviour" begin
    if Sys.isapple()
        @test tzdate(DateTime(1970), "ABC") == "1970-01-01T00:00:00+0000 (UTC)"
        @test tzdate(DateTime(1970), "<>+1") == "1970-01-01T00:00:00-0100 ()"
        @test tzdate(DateTime(1970), "A1") == "1970-01-01T00:00:00-0100 (A)"
        @test tzdate(DateTime(1970), "<αβc>1") == "1970-01-01T00:00:00-0100 (____c)"

        @test tzdate(DateTime(1970), "ABC24") == "1970-01-01T00:00:00-2400 (ABC)"
        @test tzdate(DateTime(1970), "ABC25") == "1970-01-01T00:00:00-2500 (ABC)"

        @test tzdate(DateTime(1970), "ABC-167") == "1970-01-01T00:00:00+16700 (ABC)"
        @test tzdate(DateTime(1970), "ABC-168") == "1970-01-01T00:00:00+0000 (UTC)"

        tz = "FOO0BAR0,M1.5.6,1"
        @test tzdate(DateTime(2020, 1, 25, 1, 59, 59), tz) == "2020-01-25T01:59:59+0000 (FOO)"
        @test tzdate(DateTime(2020, 1, 25, 2,  0,  0), tz) == "2020-01-25T02:00:00+0000 (BAR)"

        tz = "FOO0BAR0,365,1"
        @test tzdate(DateTime(2020,  1,  2, 1, 59, 59), tz) == "2020-01-02T01:59:59+0000 (BAR)"
        @test tzdate(DateTime(2020,  1,  2, 2,  0,  0), tz) == "2020-01-02T02:00:00+0000 (FOO)"
        @test tzdate(DateTime(2020, 12, 31, 1, 59, 59), tz) == "2020-12-31T01:59:59+0000 (FOO)"
        @test tzdate(DateTime(2020, 12, 31, 2,  0,  0), tz) == "2020-12-31T02:00:00+0000 (BAR)"

        @test tzdate(DateTime(2021, 1, 2, 1, 59, 59), tz) == "2021-01-02T01:59:59+0000 (BAR)"
        @test tzdate(DateTime(2021, 1, 2, 2,  0,  0), tz) == "2021-01-02T02:00:00+0000 (FOO)"
        @test tzdate(DateTime(2022, 1, 1, 1, 59, 59), tz) == "2022-01-01T01:59:59+0000 (FOO)"
        @test tzdate(DateTime(2022, 1, 1, 2,  0,  0), tz) == "2022-01-01T02:00:00+0000 (BAR)"

        @test tzdate(DateTime(2021), "FOO-1BAR-2,1/0,1/8761") == "2021-01-01T00:00:00+0000 (UTC)"
        @test tzdate(DateTime(2021), "FOO-1BAR-2,1/0,1/8762") == "2021-01-01T00:00:00+0000 (UTC)"

        tz = "FOO0BAR0,1/+1,2/-1"
        @test tzdate(DateTime(2020, 1, 2,  0, 59, 59), tz) == "2020-01-02T00:59:59+0000 (UTC)"
        @test tzdate(DateTime(2020, 1, 2,  1,  0,  0), tz) == "2020-01-02T01:00:00+0000 (UTC)"
        @test tzdate(DateTime(2020, 1, 2, 22, 59, 59), tz) == "2020-01-02T22:59:59+0000 (UTC)"
        @test tzdate(DateTime(2020, 1, 2, 23,  0,  0), tz) == "2020-01-02T23:00:00+0000 (UTC)"

    elseif Sys.isunix()
        @test tzdate(DateTime(1970), "ABC") == "1970-01-01T00:00:00+0000 (ABC)"
        @test tzdate(DateTime(1970), "<>+1") == "1970-01-01T00:00:00+0000 ()"
        @test tzdate(DateTime(1970), "A1") == "1970-01-01T00:00:00+0000 ()"
        @test tzdate(DateTime(1970), "<αβc>1") == "1970-01-01T00:00:00+0000 ()"

        @test tzdate(DateTime(1970), "ABC24") == "1970-01-01T00:00:00-2400 (ABC)"
        @test tzdate(DateTime(1970), "ABC25") == "1970-01-01T00:00:00-2400 (ABC)"

        @test tzdate(DateTime(1970), "ABC-167") == "1970-01-01T00:00:00+2400 (ABC)"
        @test tzdate(DateTime(1970), "ABC-168") == "1970-01-01T00:00:00+2400 (ABC)"

        tz = "FOO0BAR0,M1.5.6,1"
        @test tzdate(DateTime(2020, 1, 25), tz) == "2020-01-25T00:00:00+0000 (FOO)"
        @test tzdate(DateTime(2020, 1, 26), tz) == "2020-01-26T00:00:00+0000 (BAR)"

        tz = "FOO0BAR0,365,1"
        @test tzdate(DateTime(2020,  1,  2, 1, 59, 59), tz) == "2020-01-02T01:59:59+0000 (BAR)"
        @test tzdate(DateTime(2020,  1,  2, 2,  0,  0), tz) == "2020-01-02T02:00:00+0000 (FOO)"
        @test tzdate(DateTime(2020, 12, 31, 1, 59, 59), tz) == "2020-12-31T01:59:59+0000 (FOO)"
        @test tzdate(DateTime(2020, 12, 31, 2,  0,  0), tz) == "2020-12-31T02:00:00+0000 (BAR)"

        @test tzdate(DateTime(2021,  1,  2,  1, 59, 59), tz) == "2021-01-02T01:59:59+0000 (BAR)"
        @test tzdate(DateTime(2021,  1,  2,  2,  0,  0), tz) == "2021-01-02T02:00:00+0000 (FOO)"
        @test tzdate(DateTime(2021, 12, 31, 23, 59, 59), tz) == "2021-12-31T23:59:59+0000 (FOO)"
        @test tzdate(DateTime(2022,  1,  1,  0,  0,  0), tz) == "2022-01-01T00:00:00+0000 (BAR)"

        @test tzdate(DateTime(2021), "FOO-1BAR-2,1/0,1/8761") == "2021-01-01T00:00:00+0100 (FOO)"
        @test tzdate(DateTime(2021), "FOO-1BAR-2,1/0,1/8762") == "2021-01-01T00:00:00+0200 (BAR)"

        tz = "FOO0BAR0,1/+1,2/-1"
        @test tzdate(DateTime(2020, 1, 2,  0, 59, 59), tz) == "2020-01-02T00:59:59+0000 (FOO)"
        @test tzdate(DateTime(2020, 1, 2,  1,  0,  0), tz) == "2020-01-02T01:00:00+0000 (BAR)"
        @test tzdate(DateTime(2020, 1, 2, 22, 59, 59), tz) == "2020-01-02T22:59:59+0000 (BAR)"
        @test tzdate(DateTime(2020, 1, 2, 23,  0,  0), tz) == "2020-01-02T23:00:00+0000 (FOO)"
    end
end
