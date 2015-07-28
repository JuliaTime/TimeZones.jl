function Base.string(dt::ZonedDateTime)
    offset = tzoffset(dt.zone)

    v = offset.value
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    hh = @sprintf("%+03i", h)
    mm = lpad(m, 2, "0")
    ss = s != 0 ? lpad(s, 2, "0") : ""

    local_dt = dt.utc_datetime + offset
    return "$local_dt$hh:$mm$(ss)"
end
Base.show(io::IO,dt::ZonedDateTime) = print(io,string(dt))

# Timezones.parse(dt::String,format::String) --> (DateTime,tz::String)
# Timezones.format(dt,format::String) --> dt::String
function parse(x::String,format::String;locale#=::String=#="english")
    # format = "yyyy-mm-ddTHH:MM:SS.ss zzz"; x = "2014-07-01T19:01:02.619 America/Los_Angeles"
    # "yyyy-mm-ddTHH:MM:SS ZZZ"
    # strip out timezone
    tzind = first(search(format,r"z|Z"))
    dt_format = format[1:tzind-1]
    df = Dates.DateFormat(dt_format,locale)
    tr = df.trans[end]
    # send to Dates.parse
    tz_dt_ind = first(rsearch(x,tr))
    dt_string = x[1:tz_dt_ind]
    dt = Dates.DateTime(dt_string,df)
    #
    tz = parsetimezone(x[tz_dt_ind:end])

end