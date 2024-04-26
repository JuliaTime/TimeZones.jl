using TimeZones: UNICODE_CLDR_VERSION, WINDOWS_TRANSLATION

@test occursin(r"^release-\d+(-\d+)?$", UNICODE_CLDR_VERSION)
@test WINDOWS_TRANSLATION["Central European Standard Time"] == "Europe/Warsaw"
