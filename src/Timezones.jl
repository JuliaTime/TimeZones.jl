module Timezones

using Dates

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



end # module
