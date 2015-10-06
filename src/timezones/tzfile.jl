# Parsing tzfiles (http://man7.org/linux/man-pages/man5/tzfile.5.html)
immutable TransitionTimeInfo
    gmtoff::Int32     # tt_gmtoff
    isdst::Int8       # tt_isdst
    abbrindex::UInt8  # tt_abbrind
end

abbreviation(chars::Array{UInt8}, offset::Integer=1) = ascii(pointer(chars[offset:end]))

function read_tzfile(io::IO, name::AbstractString)
    magic = readbytes(io, 4)
    @assert magic == b"TZif" "Magic file identifier \"TZif\" not found."

    version = readbytes(io, 1)  # Format version (ASCII NUL ('\0') or a '2' (0x32))
    readbytes(io, 15)  # Fifteen bytes reserved for future use
    tzh_ttisgmtcnt = ntoh(read(io, Int32))  # Number of UTC/local indicators
    tzh_ttisstdcnt = ntoh(read(io, Int32))  # Number of standard/wall indicators
    tzh_leapcnt = ntoh(read(io, Int32))  # Number of leap seconds
    tzh_timecnt = ntoh(read(io, Int32))  # Number of transition dates
    tzh_typecnt = ntoh(read(io, Int32))  # Number of TransitionTimeInfos (must be > 0)
    tzh_charcnt = ntoh(read(io, Int32))  # Number of timezone abbreviation characters

    transitions = Array{Int32}(tzh_timecnt)
    for i in eachindex(transitions)
        transitions[i] = ntoh(read(io, Int32))
    end
    lindexes = Array{UInt8}(tzh_timecnt)
    for i in eachindex(lindexes)
        lindexes[i] = ntoh(read(io, UInt8)) + 1 # Julia uses 1 indexing
    end
    ttinfo = Array{TransitionTimeInfo}(tzh_typecnt)
    for i in eachindex(ttinfo)
        ttinfo[i] = TransitionTimeInfo(
            ntoh(read(io, Int32)),
            ntoh(read(io, Int8)),
            ntoh(read(io, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    abbrs = Array{UInt8}(tzh_charcnt)
    for i in eachindex(abbrs)
        abbrs[i] = ntoh(read(io, UInt8))
    end

    # Now build the timezone object
    if length(transitions) == 0
        abbr = abbreviation(abbrs, ttinfo[1].abbrindex)
        return FixedTimeZone(Symbol(abbr), Offset(ttinfo[1].gmtoff))
    else
        # Calculate transition info
        transition_info = Transition[]
        prev_utc = 0
        prev_dst = 0
        dst = 0
        utc = 0
        for i in eachindex(transitions)
            inf = ttinfo[lindexes[i]]
            utcoffset = inf.gmtoff
            if inf.isdst == 0
                utc = inf.gmtoff
                dst = 0
            else
                if prev_dst == 0
                    utc = prev_utc
                    dst = inf.gmtoff - prev_utc
                else
                    utc = inf.gmtoff - prev_dst
                    dst = prev_dst
                end
            end

            # Sometimes it likes to be fancy and have multiple names in one for
            # example "WSST" at abbrindex 5 turns into "SST" at abbrindex 6
            abbr = abbreviation(abbrs, inf.abbrindex)
            tz = FixedTimeZone(abbr, utc, dst)

            if isempty(transition_info) || last(transition_info).zone != tz
                push!(transition_info, Transition(unix2datetime(transitions[i]), tz))
            end

            prev_utc = utc
            prev_dst = dst
        end
        return VariableTimeZone(Symbol(name), transition_info)
    end
end
