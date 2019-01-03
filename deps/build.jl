import TimeZones: build

# ENV variable allows users to modify the default to be "latest". Do NOT use "latest"
# as the default here as can make it difficult to debug to past versions of working code.
# Note: Also allows us to only download a single tzdata version during CI jobs.
build(get(ENV, "JULIA_TZ_VERSION", "2018i"))
