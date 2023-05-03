# Thread-local TimeZone caches, which caches time zones _per thread_, allowing thread-safe
# caching. Note that this means the cache will grow in size, and may store redundant objects
# accross multiple threads, but this extra space usage allows for fast, lock-free access
# to the cache, while still being thread-safe.
# Use a separate cache for FixedTimeZone (which is `isbits`) so the container is concretely
# typed and we avoid allocating a FixedTimeZone every time we get one from the cache.
const THREAD_FTZ_CACHES = Vector{Dict{String,Tuple{FixedTimeZone,Class}}}()
const THREAD_VTZ_CACHES = Vector{Dict{String,Tuple{VariableTimeZone,Class}}}()

# Based upon the thread-safe Global RNG implementation in the Random stdlib:
# https://github.com/JuliaLang/julia/blob/e4fcdf5b04fd9751ce48b0afc700330475b42443/stdlib/Random/src/RNGs.jl#L369-L385
@inline _ftz_cache() = _ftz_cache(Threads.threadid())
@inline _vtz_cache() = _vtz_cache(Threads.threadid())
@noinline function _ftz_cache(tid::Int)
    0 < tid <= length(THREAD_FTZ_CACHES) || _ftz_cache_length_assert()
    if @inbounds isassigned(THREAD_FTZ_CACHES, tid)
        @inbounds cache = THREAD_FTZ_CACHES[tid]
    else
        cache = eltype(THREAD_FTZ_CACHES)()
        @inbounds THREAD_FTZ_CACHES[tid] = cache
    end
    return cache
end
@noinline function _vtz_cache(tid::Int)
    0 < tid <= length(THREAD_VTZ_CACHES) || _vtz_cache_length_assert()
    if @inbounds isassigned(THREAD_VTZ_CACHES, tid)
        @inbounds cache = THREAD_VTZ_CACHES[tid]
    else
        cache = eltype(THREAD_VTZ_CACHES)()
        @inbounds THREAD_VTZ_CACHES[tid] = cache
    end
    return cache
end
@noinline _ftz_cache_length_assert() = @assert false "0 < tid <= length(THREAD_FTZ_CACHES)"
@noinline _vtz_cache_length_assert() = @assert false "0 < tid <= length(THREAD_VTZ_CACHES)"

function _reset_tz_cache()
    # ensures that we didn't save a bad object
    resize!(empty!(THREAD_FTZ_CACHES), Threads.nthreads())
    resize!(empty!(THREAD_VTZ_CACHES), Threads.nthreads())
end

"""
    TimeZone(str::AbstractString) -> TimeZone

Constructs a `TimeZone` subtype based upon the string. If the string is a recognized
standard time zone name then data is loaded from the compiled IANA time zone database.
Otherwise the string is parsed as a fixed time zone.

A list of recognized standard and legacy time zones names can is available by running
`timezone_names()`. Supported fixed time zone string formats can be found in docstring for
[`FixedTimeZone(::AbstractString)`](@ref).

## Examples
```jldoctest
julia> TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> TimeZone("UTC")
UTC
```
"""
TimeZone(::AbstractString)

"""
    TimeZone(str::AbstractString, mask::Class) -> TimeZone

Similar to [`TimeZone(::AbstractString)`](@ref) but allows you to control what time zone
classes are allowed to be constructed with `mask`. Can be used to construct time zones
which are classified as "legacy".

## Examples
```jldoctest
julia> TimeZone("US/Pacific")
ERROR: ArgumentError: The time zone "US/Pacific" is of class `TimeZones.Class(:LEGACY)` which is currently not allowed by the mask: `TimeZones.Class(:FIXED) | TimeZones.Class(:STANDARD)`

julia> TimeZone("US/Pacific", TimeZones.Class(:LEGACY))
US/Pacific (UTC-8/UTC-7)
```
"""
TimeZone(::AbstractString, ::Class)

function TimeZone(str::AbstractString, mask::Class=Class(:DEFAULT))
    # Note: If the class `mask` does not match the time zone we'll still load the
    # information into the cache to ensure the result is consistent.
    ftz, class = get(_ftz_cache(), str, (nothing, Class(:NONE)))
    if ftz !== nothing
        _check_class(mask, class, str)
        return ftz::FixedTimeZone
    end

    vtz, class = get(_vtz_cache(), str, (nothing, Class(:NONE)))
    if vtz !== nothing
        _check_class(mask, class, str)
        return vtz::VariableTimeZone
    end

    # We need to compute the timezone
    tz_path = joinpath(_COMPILED_DIR[], split(str, "/")...)
    if isfile(tz_path)
        tz, class = open(TZJFile.read, tz_path, "r")(str)::Tuple{TimeZone,Class}
        if tz isa FixedTimeZone
            _ftz_cache()[str] = (tz, class)
            _check_class(mask, class, str)
            return tz::FixedTimeZone
        elseif tz isa VariableTimeZone
            _vtz_cache()[str] = (tz, class)
            _check_class(mask, class, str)
            return tz::VariableTimeZone
        end
    elseif occursin(FIXED_TIME_ZONE_REGEX, str)
        ftz = FixedTimeZone(str)
        class = Class(:FIXED)
        _ftz_cache()[str] = (ftz, class)
        _check_class(mask, class, str)
        return ftz
    elseif !isdir(_COMPILED_DIR[]) || isempty(readdir(_COMPILED_DIR[]))
        # Note: Julia 1.0 supresses the build logs which can hide issues in time zone
        # compliation which result in no tzdata time zones being available.
        throw(ArgumentError(
            "Unable to find time zone \"$str\". Try running `TimeZones.build()`."
        ))
    else
        throw(ArgumentError("Unknown time zone \"$str\""))
    end
end

function _check_class(mask::Class, class::Class, str)
    if mask & class == Class(:NONE)
        throw(ArgumentError(
            "The time zone \"$str\" is of class `$(repr(class))` which is " *
            "currently not allowed by the mask: `$(repr(mask))`"
        ))
    end
    return nothing
end

"""
    @tz_str -> TimeZone

Constructs a `TimeZone` subtype based upon the string at parse time. See docstring of
`TimeZone` for more details.

```julia
julia> tz"Africa/Nairobi"
Africa/Nairobi (UTC+3)
```
"""
macro tz_str(str)
    TimeZone(str)
end

function _get_from_cache(str)
    (tz, class) = get(_ftz_cache(), str, (nothing, Class(:NONE)))
    tz !== nothing && return (tz, class)
    (tz, class) = get(_vtz_cache(), str, (nothing, Class(:NONE)))
    return (tz, class)
end

"""
    istimezone(str::AbstractString, mask::Class=Class(:DEFAULT)) -> Bool

Check whether a string is a valid for constructing a `TimeZone` with the provided `mask`.
"""
function istimezone(str::AbstractString, mask::Class=Class(:DEFAULT))
    # Start by performing quick FIXED class test
    if mask & Class(:FIXED) != Class(:NONE) && occursin(FIXED_TIME_ZONE_REGEX, str)
        return true
    end

    # Perform more expensive checks against pre-compiled time zones
    tz, class = _get_from_cache(str)
    if tz === nothing
        tz_path = joinpath(_COMPILED_DIR[], split(str, "/")...)
        if isfile(tz_path)
            # Cache the data since we're already performing the deserialization
            tz, class = open(TZJFile.read, tz_path, "r")(str)
            if tz isa FixedTimeZone
                _ftz_cache()[str] = (tz, class)
            elseif tz isa VariableTimeZone
                _vtz_cache()[str] = (tz, class)
            end
        end
    end
    return tz !== nothing && mask & class != Class(:NONE)
end
