"""
    timezone_names() -> Array{AbstractString}

Returns a sorted list of all of the valid names for constructing a `TimeZone`.
"""
function timezone_names()
    # Note: Olson time zone names are typically encoded only in ASCII.
    names = AbstractString[]
    check = Tuple{AbstractString,AbstractString}[(COMPILED_DIR, "")]

    for (dir, partial) in check
        for filename in readdir(dir)
            startswith(filename, ".") && continue

            path = joinpath(dir, filename)
            name = partial == "" ? filename : join([partial, filename], "/")

            if isdir(path)
                push!(check, (path, name))
            else
                push!(names, name)
            end
        end
    end

    return sort!(names)
end

"""
    all_timezones() -> Array{TimeZone}

Returns all pre-computed `TimeZone`s.
"""
function all_timezones()
    results = TimeZone[]
    for name in timezone_names()
        push!(results, TimeZone(name))
    end
    return results
end

"""
    timezones_from_abbr(abbr) -> Array{TimeZone}

Returns all `TimeZone`s that have the specified abbrevation
"""
function timezones_from_abbr end

function timezones_from_abbr(abbr::Symbol)
    results = TimeZone[]
    for tz in all_timezones()
        if isa(tz, FixedTimeZone)
            tz.name == abbr && push!(results, tz)
        else
            for t in tz.transitions
                if t.zone.name == abbr
                    push!(results, tz)
                    break
                end
            end
        end
    end
    return results
end
timezones_from_abbr(abbr::AbstractString) = timezones_from_abbr(Symbol(abbr))

"""
    timezone_abbrs -> Array{AbstractString}

Returns a sorted list of all pre-computed time zone abbrevations.
"""
function timezone_abbrs()
    abbrs = Set{AbstractString}()
    for tz in all_timezones()
        if isa(tz, FixedTimeZone)
            push!(abbrs, string(tz.name))
        else
            for t in tz.transitions
                push!(abbrs, string(t.zone.name))
            end
        end
    end
    return sort!(collect(abbrs))
end
