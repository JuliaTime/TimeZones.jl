import TimeZones.WindowsTimeZoneIDs

xml_file = joinpath(DEPS_DIR, "local", "windowsZones2017a.xml")

trans = TimeZones.WindowsTimeZoneIDs.compile(xml_file)
@test trans["Central European Standard Time"] == "Europe/Warsaw"

mktempdir() do temp_dir
    translation_file = joinpath(temp_dir, "windows_to_posix")
    @test !isfile(translation_file)

    # Does not perform download
    TimeZones.WindowsTimeZoneIDs.build(dirname(xml_file), translation_file)
    @test isfile(translation_file)

    trans = TimeZones.WindowsTimeZoneIDs.load_translation(translation_file)
    @test isa(trans, Dict{AbstractString, AbstractString})
end
