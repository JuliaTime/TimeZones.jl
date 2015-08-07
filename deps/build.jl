import TimeZones.Olsen: REGIONS, generate_tzdata

dir = dirname(@__FILE__)
tzdata_dir = joinpath(dir, "tzdata")
compiled_dir = joinpath(dir, "compiled")

isdir(tzdata_dir) || mkdir(tzdata_dir)
isdir(compiled_dir) || mkdir(compiled_dir)

# TODO: Downloading fails regularly. Implement a retry system or file alternative
# sources.
info("Downloading TZ data")
@sync for region in REGIONS
    @async begin
        remote_file = "ftp://ftp.iana.org/tz/data/" * region
        region_file = joinpath(tzdata_dir, region)
        try
            # Note the destination file will be overwritten upon success.
            download(remote_file, region_file)
        catch e
            if isa(e, ErrorException)
                if isfile(region_file)
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


info("Pre-processing TimeZone data")
for file in readdir(compiled_dir)
    rm(joinpath(compiled_dir, file), recursive=true)
end
generate_tzdata(tzdata_dir, compiled_dir)

info("Successfully processed TimeZone data")
