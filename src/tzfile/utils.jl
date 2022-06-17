# Minimum timestamps used in the tzfile format. Typically represents negative infinity.
timestamp_min(::Type{Int64}) = -576460752303423488  # -2^59
timestamp_min(::Type{Int32}) = Int32(-2147483648)   # -2^31

function datetime2timestamp(x::DateTime, ::Type{T}) where T <: Union{Int32, Int64}
    return x != typemin(DateTime) ? convert(T, datetime2unix(x)) : timestamp_min(T)
end

function timestamp2datetime(x::T) where T <: Union{Int32, Int64}
    return x != timestamp_min(T) ? unix2datetime(x) : typemin(DateTime)
end
