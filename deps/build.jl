import TimeZones: TZDATA_DIR, COMPILED_DIR
import TimeZones.Olson: REGIONS, compile

isdir(TZDATA_DIR) || mkdir(TZDATA_DIR)
isdir(COMPILED_DIR) || mkdir(COMPILED_DIR)

# TODO: Downloading fails regularly. Implement a retry system or file alternative
# sources.
info("Downloading TZ data")
@sync for region in REGIONS
    @async begin
        remote_file = "ftp://ftp.iana.org/tz/data/" * region
        region_file = joinpath(TZDATA_DIR, region)
        remaining = 3

        while remaining > 0
            try
                # Note the destination file will be overwritten upon success.
                download(remote_file, region_file)
                remaining = 0
            catch e
                if isa(e, ErrorException)
                    if remaining > 0
                        remaining -= 1
                    elseif isfile(region_file)
                        warn("Falling back to old region file $region. Unable to download: $remote_file")
                    else
                        error("Missing region file $region. Unable to download: $remote_file")
                    end
                else
                    rethrow()
                end
            end
        end
    end
end


info("Pre-processing TimeZone data")
for file in readdir(COMPILED_DIR)
    rm(joinpath(COMPILED_DIR, file), recursive=true)
end
compile(TZDATA_DIR, COMPILED_DIR)

info("Successfully processed TimeZone data")
