using TimeZones.WindowsTimeZoneIDs

xml_file = TimeZones.WindowsTimeZoneIDs._WINDOWS_XML_FILE_PATH[]
!isfile(xml_file) && error("Missing required XML file. Run Pkg.build(\"TimeZones\").")

trans = TimeZones.WindowsTimeZoneIDs.compile(xml_file)
@test trans["Central European Standard Time"] == "Europe/Warsaw"

mktempdir() do temp_dir
    xml_file = joinpath(temp_dir, "windowZones.xml")
    @test !isfile(xml_file)

    empty!(TimeZones.WindowsTimeZoneIDs.WINDOWS_TRANSLATION)
    @test isempty(TimeZones.WindowsTimeZoneIDs.WINDOWS_TRANSLATION)

    # Does not perform download
    TimeZones.WindowsTimeZoneIDs.build(xml_file)
    @test isfile(xml_file)
    @test !isempty(TimeZones.WindowsTimeZoneIDs.WINDOWS_TRANSLATION)
end
