const TIMESTAMP_MIN = timestamp_min(Int64)

function datetime2timestamp(x, sentinel)
    return x != sentinel ? convert(Int64, datetime2unix(x)) : TIMESTAMP_MIN
end

function timestamp2datetime(x::Int64, sentinel)
    return x != TIMESTAMP_MIN ? unix2datetime(x) : sentinel
end
