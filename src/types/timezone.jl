# Thread-local TimeZone cache, which caches time zones _per thread_, allowing thread-safe
# caching. Note that this means the cache will grow in size, and may store redundant objects
# accross multiple threads, but this extra space usage allows for fast, lock-free access
# to the cache, while still being thread-safe.
const THREAD_TZ_CACHES = Vector{Dict{String,Tuple{TimeZone,Class}}}()

# Holding a lock during construction of a specific TimeZone prevents multiple Tasks (on the
# same or different threads) from attempting to construct the same TimeZone object, and
# allows them all to share the result.
const tz_cache_mutex = ReentrantLock()
const TZ_CACHE_FUTURES = Dict{String,Channel{Tuple{TimeZone,Class}}}()  # Guarded by: tz_cache_mutex

# Based upon the thread-safe Global RNG implementation in the Random stdlib:
# https://github.com/JuliaLang/julia/blob/e4fcdf5b04fd9751ce48b0afc700330475b42443/stdlib/Random/src/RNGs.jl#L369-L385
@inline _tz_cache() = _tz_cache(Threads.threadid())
@noinline function _tz_cache(tid::Int)
    0 < tid <= length(THREAD_TZ_CACHES) || _tz_cache_length_assert()
    if @inbounds isassigned(THREAD_TZ_CACHES, tid)
        @inbounds cache = THREAD_TZ_CACHES[tid]
    else
        cache = eltype(THREAD_TZ_CACHES)()
        @inbounds THREAD_TZ_CACHES[tid] = cache
    end
    return cache
end
@noinline _tz_cache_length_assert() = @assert false "0 < tid <= length(THREAD_TZ_CACHES)"

function _tz_cache_init()
    resize!(empty!(THREAD_TZ_CACHES), Threads.nthreads())
end
# ensures that we didn't save a bad object
function _reset_tz_cache()
    # Since we use thread-local caches, we spawn a task on _each thread_ to clear that
    # thread's local cache.
    Threads.@threads for i in 1:Threads.nthreads()
        @assert Threads.threadid() === i "TimeZones.TZData.compile() must be called from the main, top-level Task."
        empty!(_tz_cache())
    end
    @lock tz_cache_mutex begin
        empty!(TZ_CACHE_FUTURES)
    end
    return nothing
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
    tz, class = get!(_tz_cache(), str) do
        # Even though we're using Thread-local caches, we still need to lock during
        # construction to prevent multiple tasks redundantly constructing the same object,
        # and potential thread safety violations due to Tasks migrating threads.
        # NOTE that we only grab the lock if the TZ doesn't exist, so the mutex contention
        # is not on the critical path for most constructors. :)
        constructing = false
        # We lock the mutex, but for only a short, *constant time* duration, to grab the
        # future for this TimeZone, or create the future if it doesn't exist.
        future = @lock tz_cache_mutex begin
            get!(TZ_CACHE_FUTURES, str) do
                constructing = true
                Channel{Tuple{TimeZone,Class}}(1)
            end
        end
        if constructing
            tz_path = joinpath(TZData.COMPILED_DIR, split(str, "/")...)

            t = if isfile(tz_path)
                open(deserialize, tz_path, "r")
            elseif occursin(FIXED_TIME_ZONE_REGEX, str)
                FixedTimeZone(str), Class(:FIXED)
            elseif !isdir(TZData.COMPILED_DIR) || isempty(readdir(TZData.COMPILED_DIR))
                # Note: Julia 1.0 supresses the build logs which can hide issues in time zone
                # compliation which result in no tzdata time zones being available.
                throw(ArgumentError(
                    "Unable to find time zone \"$str\". Try running `TimeZones.build()`."
                ))
            else
                throw(ArgumentError("Unknown time zone \"$str\""))
            end

            put!(future, t)
        else
            fetch(future)
        end
    end

    if mask & class == Class(:NONE)
        throw(ArgumentError(
            "The time zone \"$str\" is of class `$(repr(class))` which is " *
            "currently not allowed by the mask: `$(repr(mask))`"
        ))
    end

    return tz
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
    tz, class = get(_tz_cache(), str) do
        tz_path = joinpath(TZData.COMPILED_DIR, split(str, "/")...)

        if isfile(tz_path)
            # Cache the data since we're already performing the deserialization
            _tz_cache()[str] = open(deserialize, tz_path, "r")
        else
            nothing, Class(:NONE)
        end
    end

    return tz !== nothing && mask & class != Class(:NONE)
end

# After `broadcastable` was defined but before this was addressed in the `Dates` stdlib
# - Broadcastable introduction: https://github.com/JuliaLang/julia/pull/26601
# - Fixed in Dates: https://github.com/JuliaLang/julia/pull/30159
# Note: The change was backported to 1.1 as well.
if v"0.7.0-DEV.4743" <= VERSION < v"1.1.0-DEV.722" || v"1.2-" <= VERSION < v"1.2.0-DEV.114"
    Base.broadcastable(tz::TimeZone) = Ref(tz)
end
