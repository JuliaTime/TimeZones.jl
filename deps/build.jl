mkpath(joinpath(@__DIR__, "tzarchive"))
mkpath(joinpath(@__DIR__, "compiled", string(VERSION)))
touch(joinpath(@__DIR__, "active_version"))
touch(joinpath(@__DIR__, "latest"))

using TimeZones: build

build()
