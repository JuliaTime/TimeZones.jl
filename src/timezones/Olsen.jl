module Olsen

using Base.Dates
import Compat: parse

import ..TimeZones: TimeZone, FixedTimeZone, VariableTimeZone, Transition

# Convenience type for working with HH:MM
immutable Time
    seconds::Int
end
const ZERO = Time(0)

function Time(hour::Int, minute::Int, second::Int)
    Time(hour * 3600 + minute * 60 + second)
end

function Time(s::String)
    # "-" represents 0:00 for some DST rules
    s == "-" && return ZERO
    parsed = map(n -> parse(Int, n), split(s, ':'))

    # Only can handle up to hour, minute, second.
    length(parsed) > 3 && error("Invalid Time string")
    any(parsed[2:end] .< 0) && error("Invalid Time string")

    # Handle variations where minutes and seconds may be excluded.
    values = [0,0,0]
    values[1:length(parsed)] = parsed

    if values[1] < 0
        for i in 2:length(values)
            values[i] = -values[i]
        end
    end

    return Time(values...)
end

hour(t::Time) = div(t.seconds, 3600)
minute(t::Time) = rem(div(t.seconds, 60), 60)
second(t::Time) = rem(t.seconds, 60)

function hourminutesecond(t::Time)
    h, r = divrem(t.seconds, 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

as_seconds(t::Time) = t.seconds
(+)(x::Time,y::Time) = Time(as_seconds(x) + as_seconds(y))
(-)(x::Time,y::Time) = Time(as_seconds(x) - as_seconds(y))
(+)(x::DateTime,y::Time) = x + Second(as_seconds(y))
(-)(x::DateTime,y::Time) = x - Second(as_seconds(y))

# https://en.wikipedia.org/wiki/ISO_8601#Times
function Base.string(t::Time)
    neg = as_seconds(t) < 0 ? "-" : ""
    h, m, s = map(abs, hourminutesecond(t))
    @sprintf("%s%02d:%02d:%02d", neg, h, m, s)
end

Base.show(io::IO, t::Time) = print(io, string(t))


# Zone type maps to an Olsen Timezone database entity
type Zone
    gmtoffset::Time
    save::Time
    rules::String
    format::String
    until::Nullable{DateTime}
    until_flag::Int
end

# Rules govern how Daylight Savings transitions happen for a given timezone
type Rule
    from::Nullable{Int}  # First year rule applies
    to::Nullable{Int}    # Rule applies up until, but not including this year
    month::Int           # Month in which DST transition happens
    on::Function         # Anonymous boolean function to determine day
    at::Time             # Hour and minute at which the transition happens
    at_flag::Int         # 0, 1, 2 = Local wall time ('w' or blank), UTC time ('u'), Local Standard time ('s')
    save::Time           # How much time is "saved" in daylight savings transition
    letter::String       # Timezone abbreviation letter change; i.e CST => CDT
end

# Max date that we create DST transition instants for
const MINDATE = DateTime(1917,1,1)
const MAXDATE = DateTime(2038,12,31)

# Helper functions/data
const MONTHS = Dict("Jan"=>1,"Feb"=>2,"Mar"=>3,"Apr"=>4,"May"=>5,"Jun"=>6,
                "Jul"=>7,"Aug"=>8,"Sep"=>9,"Oct"=>10,"Nov"=>11,"Dec"=>12)

const DAYS = Dict("Mon"=>1,"Tue"=>2,"Wed"=>3,"Thu"=>4,"Fri"=>5,"Sat"=>6,"Sun"=>7)

# Create adjuster functions such as "lastSun".
for (abbr, dayofweek) in DAYS
    sym = symbol("last" * abbr)
    @eval (
        function $sym(dt)
            return dayofweek(dt) == $dayofweek &&
            dayofweekofmonth(dt) == daysofweekinmonth(dt)
        end
    )
end


function parseflag(s::String)
    if s == "" || s == "w"
        return 0
    elseif s == "u"
        return 1
    elseif s == "s"
        return 2
    else
        error("Unhanbled flag $s")
    end
end

# Olsen timezone dates can be a single year (1900), yyyy-mm-dd (1900-Jan-01),
# or minute-precision (1900-Jan-01 2:00).
# They can also be given in Local Wall Time, UTC time (u), or Local Standard time (s)
function parsedate(s::String)
    s = replace(s, r"\s+", " ")
    num_periods = length(split(s, " "))
    s, letter = num_periods > 3 && isalpha(s[end]) ? (s[1:end-1], s[end:end]) : (s, "")
    if contains(s,"lastSun")
        dt = DateTime(replace(s, "lastSun", "1", 1), "yyyy uuu d H:MM:SS")
        dt = tonext(lastSun, dt; same=true)
    elseif contains(s,"lastSat")
        dt = DateTime(replace(s, "lastSat", "1", 1), "yyyy uuu d H:MM:SS")
        dt = tonext(lastSat, dt; same=true)
    elseif contains(s,"Sun>=1")
        dt = DateTime(replace(s,"Sun>=", "", 1),"yyyy uuu d H:MM:SS")
        dt = tonext(d -> dayofweek(d) == Sun, dt; same=true)
    else
        format = join(split("yyyy uuu dd HH:MM:SS", " ")[1:num_periods], ' ')
        periods = Dates.parse(s, DateFormat(format))

        # Deal with zone "Pacific/Apia" which has a 24:00 datetime.
        if length(periods) > 3 && periods[4] == Hour(24)
            periods[4] = Hour(0)
            periods[3] += Day(1)
        end
        dt = DateTime(periods...)
    end

    # TODO: I feel like there are issues here.
    # If the time is UTC, we add back the offset and any saved amount
    # If it's local standard time, we just need to add any saved amount
    # return letter == 's' ? (dt - save) : (dt - offset - save)

    return dt, parseflag(letter)
end


function ruleparse(from, to, rule_type, month, on, at, save, letter)
    from_int = Nullable{Int}(from == "min" ? nothing : parse(Int, from))
    to_int = Nullable{Int}(to == "only" ? from_int : to == "max" ? nothing : parse(Int, to))
    month_int = MONTHS[month]

    # Now we need to get the right anonymous function
    # for determining the right day for transitioning
    if ismatch(r"last\w\w\w", on)
        # We pre-built these functions above
        # They follow the format: "lastSun", "lastMon".
        on_func = eval(symbol(on))
    elseif ismatch(r"\w\w\w[<>]=\d\d?", on)
        # The first day of the week that occurs before or after a given day of month.
        # i.e. Sun>=8 refers to the Sunday after the 8th of the month
        # or in other words, the 2nd Sunday.
        dow = DAYS[match(r"\w\w\w", on).match]
        dom = parse(Int, match(r"\d\d?", on).match)
        if ismatch(r"<=", on)
            on_func = @eval (dt -> day(dt) <= $dom && dayofweek(dt) == $dow)
        else
            on_func = @eval (dt -> day(dt) >= $dom && dayofweek(dt) == $dow)
        end
    elseif ismatch(r"\d\d?", on)
        # Matches just a plain old day of the month
        dom = parse(Int, on)
        on_func = @eval (dt -> day(dt) == $dom)
    else
        error("Can't parse day of month for DST change")
    end
    # Now we get the time of the transition
    c = at[end:end]
    at_hm = Time(isalpha(c) ? at[1:end-1] : at)
    at_flag = parseflag(isalpha(c) ? c : "")
    save_hm = Time(save)
    letter = letter == "-" ? "" : letter

    # Now we've finally parsed everything we need
    return Rule(
        from_int,
        to_int,
        month_int,
        on_func,
        at_hm,
        at_flag,
        save_hm,
        letter,
    )
end

function zoneparse(gmtoff, rules, format, until="")
    # Get our offset and abbreviation string for this period
    offset = Time(gmtoff)
    format = format == "zzz" ? "" : format

    # Parse the date the line rule applies up to
    until_tuple = until == "" ? (nothing, 0) : parsedate(until)
    until_dt, until_flag = Nullable{DateTime}(until_tuple[1]), until_tuple[2]

    if rules == "-" || ismatch(r"\d",rules)
        save = Time(rules)
        rules = ""
    else
        save = ZERO
    end

    return Zone(
        offset,
        save,
        rules,
        format,
        until_dt,
        until_flag,
    )
end


function resolve(zone_name, zonesets, rulesets)
    # zones = Set{FixedTimeZone}()
    transitions = Transition[]

    # Set some default values and starting DateTime increment and away we go...
    # y = get(zonesets[zone_name][1].until)  # MINDATE
    y = DateTime(1800,1,1)
    save = ZERO
    offset = ZERO
    letter = Nullable{String}()

    for zone in zonesets[zone_name]
        offset = zone.gmtoffset
        format = zone.format
        until = get(zone.until, MAXDATE)

        if isnull(letter) && zone.rules != ""
            for rule in rulesets[zone.rules]
                if rule.save == ZERO
                    letter = Nullable{String}(rule.letter)
                    break
                end
            end
        end

        # @show y, until, format, letter, zone.rules

        # save = zone.save

        tz = FixedTimeZone(
            replace(format,"%s",get(letter,""),1),
            as_seconds(offset),
            as_seconds(save),
        )
        push!(transitions, Transition(y, tz))

        if zone.rules == ""
            y = until - offset - save
        else
            # Get the Rule that applies for this period
            ruleset = rulesets[zone.rules]
            # Now we iterate thru the years until we reach UNTIL
            while y < until
                # We need to check all Rules to see if they apply
                # for the given year
                for r in ruleset
                    # If the Rule is out of range, skip it
                    # r.from <= year(y) <= r.to || continue

                    (isnull(r.from) || year(y) >= get(r.from)) || continue
                    (isnull(r.to) || year(y) <= get(r.to)) || continue

                    # Now we need to deterimine the transition day
                    # We start at the Rule month, hour, minute
                    # And apply our boolean "on" function until we
                    # arrive at the right transition instant

                    # Add at since it could be larger than 23:59:59.
                    dt = DateTime(year(y),r.month) + r.at
                    try
                        dt = tonext(r.on, dt; same=true, limit=1000)
                    catch e
                        if isa(e, ArgumentError)
                            error("Unable to find matching day for $zone_name $dt")
                        end
                    end

                    # 0, 1, 2 = Local wall time ('w' or blank), UTC time ('u'), Local Standard time ('s')

                    # If our time was given in UTC, add back offset and save
                    # if local standard time, add back any saved amount
                    dt = r.at_flag == 1 ? dt :
                         r.at_flag == 0 ? dt - offset - save : dt - offset

                    # if year(y) < 1930
                    #     @show year(y), r.month, r.at, dt
                    # end

                    letter = Nullable{String}(r.letter)

                    # Using @sprintf would be best but it doesn't accept a format as a
                    # variable.
                    tz = FixedTimeZone(
                        replace(format,"%s",get(letter,""),1),
                        as_seconds(offset),
                        as_seconds(r.save),
                    )

                    # TODO: We can maybe reduce memory usage by reusing the same
                    # FixedTimeZone object.
                    # Note: By default pushing onto a set will replace objects.
                    # if !(tz in zones)
                    #     push!(zones, tz)
                    # else
                    #     tz = first(intersect(zones, Set([tz])))
                    # end

                    push!(transitions, Transition(dt, tz))

                    save = r.save != ZERO ? r.save : ZERO
                end
                y += Year(1)
            end
        end
        until == MAXDATE && break
    end
    sort!(transitions)
    return VariableTimeZone(zone_name, transitions)
end

function tzparse(tzfile::String)
    rules = Dict{String,Array{Rule}}()
    zones = Dict{String,Array{Zone}}()

    # For the intial pass we'll collect the zone and rule lines.
    open(tzfile) do fp
        kind = name = ""
        for line in eachline(fp)
            # Lines that start with whitespace can be considered a "continuation line"
            # which means the last found kind/name should persist.
            persist = ismatch(r"^\s", line)

            line = strip(replace(chomp(line), r"#.*$", ""))
            length(line) > 0 || continue
            line = replace(line, r"\s+", " ")

            if !persist
                kind, name, line = split(line, ' '; limit=3)
            end

            if kind == "Rule"
                rule = ruleparse(split(line, ' ')...)
                rules[name] = push!(get(rules, name, Rule[]), rule)
            elseif kind == "Zone"
                zone = zoneparse(split(line, ' '; limit=4)...)
                zones[name] = push!(get(zones, name, Zone[]), zone)
            elseif kind == "Link"
                # TODO: Handle Links
            else
                warn("Unhandled line found with type: $kind")
            end
        end
    end

    return zones, rules
end

function zone_symbol(z::Zone)
    n = z.name
    n = ismatch(r"(?<=/).+?$",n) ? match(r"(?<=/).+?$",n).match : n
    n = ismatch(r"(?<=/).+?$",n) ? match(r"(?<=/).+?$",n).match : n
    return replace(n,"-","_")
end

function generate_tzinfo(olsen_path::String,dest_path::String)
    files = [:africa,:antarctica,:asia,:australasia,
             :europe,:northamerica,:southamerica]
    zones = Zone[]
    for f in files
        append!(zones,tzparse(joinpath(olsen_path,string(f)))[1])
    end
    z_syms = [symbol(zone_symbol(x)) for x in zones]
    z_s = [a.name=>b for (a,b) in zip(zones,z_syms)]
    s_z = [a=>b.name for (a,b) in zip(z_syms,zones)]
    open(joinpath(dest_path, "tzinfo.jl"), "w") do f
        write(f,"### AUTO-GENERATED FILE ###\n\n")
        # Zone Definitions
        write(f,"#Define zone immutable for each timezone in Olson tz database\n")
        write(f,"for tz in $(repr(tuple(z_syms...)))\n")
        write(f,"\t@eval immutable \$tz <: PoliticalTimezone end\n")
        write(f,"end\n\n")
        # String=>Zone, Zone=>String mapping
        write(f,"const TIMEZONES = $(repr(s_z))\n")
        write(f,"const TIMEZONES1 = $(repr(z_s))\n")
        # Abbreviations

    end
end

function generate_tzdata(olsen_path::String,dest_path::String)
    files = [:africa,:antarctica,:asia,:australasia,
             :europe,:northamerica,:southamerica]
    for f in files
        for (name,zone) in tzparse(joinpath(olsen_path,string(f)))[1]
            open(joinpath(dest_path,zone_symbol(zone)),"w") do x
                serialize(x,zone.dst)
            end
        end
    end
end

#TODO
 #spot check times/offsets/abbrs
 #handle timezone link names
 #generate common abbreviation typealiases
 #fix abbreviation for kiev? antarctica
 #use etcetera file for generic offsets?
end # module