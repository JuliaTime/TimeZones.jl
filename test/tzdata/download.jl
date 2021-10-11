using TimeZones.TZData: LATEST_FILE, read_latest
using TimeZones.TZData: tzdata_versions

versions = tzdata_versions()
@test first(versions) == "93g"  # Earliest release
@test "2016j" in versions
