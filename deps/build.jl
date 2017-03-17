import TimeZones: build
import Compat: is_windows

if is_windows()
    import TimeZones: WIN_TRANSLATION_FILE
    using LightXML
end

build()

if is_windows()
    translation_dir = dirname(WIN_TRANSLATION_FILE)
    isdir(translation_dir) || mkdir(translation_dir)

    info("Downloading Windows to POSIX timezone name XML")

    # Retrieve a mapping of Windows timezone names to Olson timezone names.
    # Details on the contents of this file can be found at:
    # http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping
    xml_source = "http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml"
    xml_file = try
        download(xml_source)
    catch err
        warn(err)
        info("Falling back to cached XML")
        joinpath(translation_dir, "windowsZones.xml")
    end

    info("Pre-processing Windows translation")

    # Get the timezone conversions from the file
    xdoc = parse_file(xml_file)
    xroot = root(xdoc)
    windows_zones = find_element(xroot, "windowsZones")
    map_timezones = find_element(windows_zones, "mapTimezones")
    map_zones = get_elements_by_tagname(map_timezones, "mapZone")

    # TODO: Eliminate the Etc/* POSIX names here? See Windows section of `localzone`

    # Dictionary to store the windows to timezone conversions
    translation = Dict{AbstractString,AbstractString}()
    for map_zone in map_zones
        # Territory "001" is the global default
        if attribute(map_zone, "territory") == "001"
            win_name = attribute(map_zone, "other")
            posix_name = attribute(map_zone, "type")
            translation[win_name] = posix_name
        end
    end

    open(WIN_TRANSLATION_FILE, "w") do fp
        serialize(fp, translation)
    end
end

info("Successfully processed TimeZone data")
