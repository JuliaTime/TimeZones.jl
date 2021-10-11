using TimeZones.TZData: LATEST_FILE, read_latest
using TimeZones.TZData: tzdata_url, tzdata_versions

@test tzdata_url("2016j") == "https://data.iana.org/time-zones/releases/tzdata2016j.tar.gz"
@test tzdata_url("latest") == "https://data.iana.org/time-zones/tzdata-latest.tar.gz"

versions = tzdata_versions()
@test first(versions) == "93g"  # Earliest release
@test "2016j" in versions
