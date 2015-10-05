# Parsing tzfiles (http://man7.org/linux/man-pages/man5/tzfile.5.html)
type TTInfo
    tt_gmtoff::Int32
    tt_isdst::Int8
    tt_abbrind::UInt8
end

function tzfile(file::IO, zone::AbstractString)
    magic = readbytes(file, 4)
    @assert magic == b"TZif" "Magic file identifier \"TZif\" not found."
    version = readbytes(file, 1)
    # Fifteen bytes containing zeros reserved for future use.
    readbytes(file, 15)
    # The number of UTC/local indicators stored in the file.
    tzh_ttisgmtcnt = bswap(read(file, Int32))
    # The number of standard/wall indicators stored in the file.
    tzh_ttisstdcnt = bswap(read(file, Int32))
    # The number of leap seconds for which data is stored in the file.
    tzh_leapcnt = bswap(read(file, Int32))
    # The number of "transition times" for which data is stored in the file.
    tzh_timecnt = bswap(read(file, Int32))
    # The number of "local time types" for which data is stored in the file (must not be zero).
    tzh_typecnt = bswap(read(file, Int32))
    # The number of characters of "timezone abbreviation strings" stored in the file.
    tzh_charcnt = bswap(read(file, Int32))

    transitions = Array{Int32}(tzh_timecnt)
    for index in 1:tzh_timecnt
        transitions[index] = bswap(read(file, Int32))
    end
    lindexes = Array{UInt8}(tzh_timecnt)
    for index in 1:tzh_timecnt
        lindexes[index] = bswap(read(file, UInt8)) + 1 # Julia uses 1 indexing
    end
    ttinfo = Array{TTInfo}(tzh_typecnt)
    for index in 1:tzh_typecnt
        ttinfo[index] = TTInfo(
            bswap(read(file, Int32)),
            bswap(read(file, Int8)),
            bswap(read(file, UInt8)) + 1 # Julia uses 1 indexing
        )
    end
    tznames_raw = Array{UInt8}(tzh_charcnt)
    namestart = 1
    tznames = Dict{UInt8, String}()
    for index in 1:tzh_charcnt
        tznames_raw[index] = bswap(read(file, UInt8))
        if tznames_raw[index] == '\0'
            tznames[namestart] = ascii(tznames_raw[namestart:index-1])
            namestart = index+1
        end
    end
    # Now build the timezone object
    if length(transitions) == 0
        return FixedTimeZone(Symbol(tznames[ttinfo[1].tt_abbrind]), Offset(ttinfo[1].tt_gmtoff))
    else
        # Calculate transition info
        transition_info = Transition[]
        for i in 1:length(transitions)
            inf = ttinfo[lindexes[i]]
            utcoffset = inf.tt_gmtoff
            if inf.tt_isdst == 0
                dst = 0
            else
                prev_inf = nothing
                for j in i:-1:1
                    prev_inf = ttinfo[lindexes[j]]
                    if prev_inf.tt_isdst == 0
                        continue
                    end
                end
                dst = inf.tt_gmtoff - prev_inf.tt_gmtoff # dst offset
                if dst <= 0 # Bad dst? Look further.
                    for j in i+1:length(transitions)
                        stdinf = ttinfo[lindexes[j]]
                        if stdinf.tt_isdst == 0
                            dst = inf.tt_gmtoff - stdinf.tt_gmtoff
                            if dst > 0
                                continue
                            end
                        end
                    end
                end
            end
            tzname = tznames[inf.tt_abbrind]
            push!(transition_info,
                Transition(
                    unix2datetime(transitions[i]),
                    FixedTimeZone(Symbol(tzname),
                    Offset(Int64(inf.tt_gmtoff-dst), Int64(dst)))
                )
            )
        end
        return VariableTimeZone(Symbol(zone), transition_info)
    end
end
