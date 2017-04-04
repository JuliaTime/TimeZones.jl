import TimeZones: build

# ENV variable allows us to only download a single version during CI jobs
build(get(ENV, "JULIA_TZ_VERSION", "latest"))
