module Olsen

using Base.Dates
import Base.Dates: value, toms
import Compat: parse

import ..TimeZones: TimeZone, FixedTimeZone, VariableTimeZone, Transition

# Convenience type for working with HH:MM:SS.
immutable Time <: TimePeriod
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

# TimePeriod methods
value(t::Time) = t.seconds
toms(t::Time) = t.seconds * 1000

toseconds(t::Time) = t.seconds
hour(t::Time) = div(toseconds(t), 3600)
minute(t::Time) = rem(div(toseconds(t), 60), 60)
second(t::Time) = rem(toseconds(t), 60)

function hourminutesecond(t::Time)
    h, r = divrem(toseconds(t), 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

Base.convert(::Type{Second}, t::Time) = Second(toseconds(t))
Base.convert(::Type{Millisecond}, t::Time) = Millisecond(toseconds(t) * 1000)
Base.promote_rule{P<:Union{Week,Day,Hour,Minute,Second}}(::Type{P}, ::Type{Time}) = Second
Base.promote_rule(::Type{Millisecond}, ::Type{Time}) = Millisecond

# Should be defined in Base.Dates
Base.isless(x::Period, y::Period) = isless(promote(x,y)...)

# https://en.wikipedia.org/wiki/ISO_8601#Times
function Base.string(t::Time)
    neg = toseconds(t) < 0 ? "-" : ""
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

# Min and max years that we create DST transition instants for (inclusive)
const MINYEAR = 1800
const MAXYEAR = 2038

const MINDATETIME = DateTime(MINYEAR,1,1)
const MAXDATETIME = DateTime(MAXYEAR,12,31)

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

function asutc(dt::DateTime, flag::Int, offset::Time, save::Time)
    if flag == 1
        # In UTC
        return dt
    elseif flag == 0
        # In local wall time, add back offset and saved amount
        return dt - offset - save
    else
        # In local standard time, add back any saved amount
        return dt - offset
    end
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

"""
Rules are typically ordered by the "from" than "in" fields. Since rules also
contain a "to" field the written ordering can be problematic for resolving
timezone transitions.

Example:

    # Rule  NAME    FROM    TO  TYPE    IN  ON  AT      SAVE    LETTER/S
    Rule    Poland  1918    1919    -   Sep 16  2:00s   0       -
    Rule    Poland  1919    only    -   Apr 15  2:00s   1:00    S
    Rule    Poland  1944    only    -   Apr  3  2:00s   1:00    S

    # ON         AT      SAVE    LETTER/S
    1918-09-16   2:00s   0       -
    1919-04-15   2:00s   1:00    S
    1919-09-16   2:00s   0       -
    1944-04-03   2:00s   1:00    S
"""
function order_rules(rules::Array{Rule})
    date_rules = Tuple{Date,Rule}[]

    # Note: Typically rules are orderd by "from" and "in". Unfortunately
    for rule in rules
        # Replicate the rule for each year that it is effective.
        for rule_year in get(rule.from, MINYEAR):get(rule.to, MAXYEAR)
            # Determine the rule transition day by starting at the
            # beginning of the month and applying our "on" function
            # until we reach the correct day.
            date = Date(rule_year, rule.month)
            try
                # The "on" function should evaluate to a day within the current month.
                date = tonext(rule.on, date; same=true, limit=daysinmonth(date))
            catch e
                if isa(e, ArgumentError)
                    error("Unable to find matching day for $zone_name in month $(year(date))/$(month(date))")
                else
                    rethrow(e)
                end
            end
            push!(date_rules, (date, rule))
        end
    end

    sort!(date_rules, by=el -> el[1])

    # Since we are not yet taking offsets or flags into account yet
    # there is a small chance that the results are not ordered correctly.
    last_date = typemin(Date)
    for (i, (date, rule)) in enumerate(date_rules)
        if i > 1 && last_date >= date - Day(1)
            error("Dates are probably not in order")
        end
        last_date = date
    end

    return date_rules
end


function resolve(zone_name, zonesets, rulesets)
    transitions = Transition[]

    # Set some default values and starting DateTime increment and away we go...
    start_utc = MINDATETIME
    offset = ZERO
    save = ZERO
    letter = ""

    ordered_rules = Dict{String,Array{Tuple{Date,Rule}}}()
    # zones = Set{FixedTimeZone}()

    # TODO: Make sure zonesets are ordered.
    for zone in zonesets[zone_name]
        offset = zone.gmtoffset
        format = zone.format
        # save = zone.save
        rule_name = zone.rules
        until = get(zone.until, MAXDATETIME)

        if rule_name == ""
            save = zone.save
            abbr = format

            println("Zone Start $rule_name, $(zone.gmtoffset), $save, $start_utc 1, $until $(zone.until_flag), $abbr")

            tz = FixedTimeZone(
                abbr,
                toseconds(offset),
                toseconds(save),
            )
            push!(transitions, Transition(start_utc, tz))
        else
            if !haskey(ordered_rules, rule_name)
                ordered_rules[rule_name] = order_rules(rulesets[rule_name])
            end

            rules = ordered_rules[rule_name]
            index = searchsortedlast(rules, start_utc, by=el -> isa(el, Tuple) ? el[1] : el)

            if index == 0
                #
                save = ZERO
                for (date, rule) in rules
                    if rule.save == save
                        letter = rule.letter
                        break
                    end
                end
            else
                date, rule = rules[index]
                save = rule.save
                letter = rule.letter
            end

            abbr = replace(format,"%s",letter,1)

            println("Zone Start $rule_name, $(zone.gmtoffset), $save, $start_utc 1, $until $(zone.until_flag), $abbr")

            tz = FixedTimeZone(
                abbr,
                toseconds(offset),
                toseconds(save),
            )
            push!(transitions, Transition(start_utc, tz))

            for (date, rule) in rules[max(index,1):end]
                # TODO: Problematic if rule date close to until and offset is a large positive.
                date > until && break

                # Add "at" since it could be larger than 23:59:59.
                dt = DateTime(date) + rule.at

                # Convert rule and until datetimes into UTC using the latest
                # offset and save values that occurred prior to this rule.
                dt_utc = asutc(dt, rule.at_flag, offset, save)
                until_utc = asutc(until, zone.until_flag, offset, save)

                dt_utc < until_utc || break

                save = rule.save
                letter = rule.letter

                # TMP
                abbr = replace(format,"%s",letter,1)
                if start_utc <= dt_utc
                    println("Rule $(year(date)), $dt $(rule.at_flag), $dt_utc 1, $save, $abbr")
                else
                    println("Skip $(year(date)), $dt $(rule.at_flag), $dt_utc 1, $save, $abbr")
                end

                # TODO: Is start_utc exclusive or inclusive?
                start_utc <= dt_utc || continue

                # Using @sprintf would be best but it doesn't accept a format as a
                # variable.
                abbr = replace(format,"%s",letter,1)

                tz = FixedTimeZone(
                    abbr,
                    toseconds(offset),
                    toseconds(save),
                )

                # TODO: We can maybe reduce memory usage by reusing the same
                # FixedTimeZone object.
                # Note: By default pushing onto a set will replace objects.
                # if !(tz in zones)
                #     push!(zones, tz)
                # else
                #     tz = first(intersect(zones, Set([tz])))
                # end

                push!(transitions, Transition(dt_utc, tz))

                # println("Rule $(year(date)), $dt $(rule.at_flag), $dt_utc 1, $save, $abbr")
            end
        end

        start_utc = asutc(until, zone.until_flag, offset, save)

        println("Zone End   $rule_name, $offset, $save, $start_utc 1")
        start_utc >= MAXDATETIME && break
    end

    # sort!(transitions)
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