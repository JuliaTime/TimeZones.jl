# Utility functions for testing

if VERSION < v"1.9.0-"  # https://github.com/JuliaLang/julia/pull/47367
    macro allocations(ex)
        quote
            while false; end  # want to force compilation, but v1.6 doesn't have `@force_compile`
            local stats = Base.gc_num()
            $(esc(ex))
            local diff = Base.GC_Diff(Base.gc_num(), stats)
            Base.gc_alloc_count(diff)
        end
    end
end

function ignore_output(body::Function; stdout::Bool=true, stderr::Bool=true)
    out_old = Base.stdout
    err_old = Base.stderr

    if stdout
        (out_rd, out_wr) = redirect_stdout()
    end
    if stderr
        (err_rd, err_wr) = redirect_stderr()
    end

    result = try
        body()
    finally
        if stdout
            redirect_stdout(out_old)
            close(out_wr)
            close(out_rd)
        end
        if stderr
            redirect_stderr(err_old)
            close(err_wr)
            close(err_rd)
        end
    end

    return result
end

# Used in tests as a shorter form of: `sprint(show, ..., context=:compact => true)`
show_compact = (io, args...) -> show(IOContext(io, :compact => true), args...)

# Modified the internal TimeZones cache. Should only be used as part of testing and only is
# needed when the data between the test tzdata version and the built tzdata versions differ.

function add!(cache::Dict, t::Tuple{TimeZone,TimeZones.Class})
    tz, class = t
    name = TimeZones.name(tz)
    push!(cache, name => t)
    return tz
end

function add!(cache::Dict, tz::VariableTimeZone)
    # Not all `VariableTimeZone`s are the STANDARD class. However, for testing purposes
    # the class doesn't need to be precise.
    class = TimeZones.Class(:STANDARD)
    return add!(cache, (tz, class))
end

function add!(cache::Dict, tz::FixedTimeZone)
    class = TimeZones.Class(:FIXED)
    return add!(cache, (tz, class))
end

function with_tz_cache(f, cache::Dict{String,Tuple{TimeZone,TimeZones.Class}})
    old_ftz_cache = deepcopy(TimeZones._FTZ_CACHE)
    old_vtz_cache = deepcopy(TimeZones._VTZ_CACHE)

    # Split the contents of `cache` between the fixed and variable caches
    # as appropriate.
    empty!(TimeZones._FTZ_CACHE)
    empty!(TimeZones._VTZ_CACHE)
    foreach(items(cache)) do (k, v)
        setindex!(
            isa(v, FixedTimeZone) ? TimeZones._FTZ_CACHE : TimeZones._VTZ_CACHE,
            k,
            v,
        )
    end
    copy!(TimeZones._FTZ_CACHE, cache)
    copy!(TimeZones._VTZ_CACHE, cache)

    try
        return f()
    finally
        copy!(TimeZones._FTZ_CACHE, old_ftz_cache)
        copy!(TimeZones._VTZ_CACHE, old_vtz_cache)
    end
end
