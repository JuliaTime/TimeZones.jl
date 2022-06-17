using TimeZones.TZFile: TZFile

# For this algorithm we don't really care about the internal ordering of the combined
# designations. We only care that it takes full advantage of null-terminated strings and
# that we can extract the original designations.
@testset "combine_designations" begin
    @testset "Pacific/Apia" begin
        desigs = ["LMT", "WSST", "SDT", "WSDT"]
        str, indices = TZFile.combine_designations(desigs)
        @test length(indices) == length(desigs)
        @test TZFile.get_designation.(Ref(collect(UInt8, str)), indices) == desigs
        @test ncodeunits(str) == 14
    end

    @testset "duplicates" begin
        desigs = ["ABC", "ABC"]
        str, indices = TZFile.combine_designations(desigs)
        @test length(indices) == length(desigs)
        @test TZFile.get_designation.(Ref(collect(UInt8, str)), indices) == desigs
        @test ncodeunits(str) == 4
    end

    @testset "sort stress" begin
        desigs = ["AB", "BA", "ABA", "BAB"]
        str, indices = TZFile.combine_designations(desigs)
        @test length(indices) == length(desigs)
        @test TZFile.get_designation.(Ref(collect(UInt8, str)), indices) == desigs
        @test ncodeunits(str) == 8
    end
end

# Analogous to `sprint` but returns a byte vector instead of a string. Note we could pass in
# `kwargs` here but we'll replicate the `sprint` interface instead.
function bprint(f, args...)
    io = IOBuffer()
    f(io, args...)
    return read(seekstart(io))
end

@testset "write_signature" begin
    @test bprint(TZFile.write_signature) == b"TZif"
end

@testset "write_version" begin
    @test bprint(io -> TZFile.write_version(io, version='\0')) == UInt8['\0']
    @test bprint(io -> TZFile.write_version(io, version='1')) == UInt8['1']
    @test bprint(io -> TZFile.write_version(io, version='2')) == UInt8['2']
    @test bprint(io -> TZFile.write_version(io, version='3')) == UInt8['3']
    @test_throws UndefKeywordError TZFile.write_version(IOBuffer())
end

@testset "write" begin
    # Tests the basic `FixedTimeZone` code path
    @testset "UTC" begin
        utc = FixedTimeZone("UTC", 0)
        io = IOBuffer()
        TZFile.write(io, utc)
        @test TZFile.read(seekstart(io))("UTC") == utc
    end

    # Tests the basic `VariableTimeZone` code path
    @testset "Europe/Warsaw" begin
        warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
        io = IOBuffer()
        TZFile.write(io, warsaw)
        @test TZFile.read(seekstart(io))("Europe/Warsaw") == warsaw
    end

    # Europe/Moscow has some interesting DST into DST switches that make it hard for our
    # heurstic that converts the `isdst` boolean into an offset. Ultimately, this doesn't
    # matter much as the total offset and isdst checks will be correct but the individual
    # UT/DST offset *values* may not be correct.
    @testset "Europe/Moscow" begin
        moscow = first(compile("Europe/Moscow", tzdata["europe"]))
        io = IOBuffer()
        TZFile.write(io, moscow)
        tz = TZFile.read(seekstart(io))("Europe/Moscow")
        @test tz != warsaw

        # Switching from "Moscow Double Summer Time" to "Moscow Summer Time" ends up being
        # challenging for our heurstic. Ideally the transitions would be:
        #
        # 6: 1918-05-31T19:28:41 UTC+02:31:19/+2 (MDST)
        # 7: 1918-09-15T20:28:41 UTC+02:31:19/+1 (MST)
        # 8: 1919-05-31T19:28:41 UTC+02:31:19/+2 (MDST)
        @test_broken tz.transitions[7] == moscow.transitions[7]

        # Another challenging DST switch. Fun fact this switch was done to save fuel and
        # lighting materials: http://istmat.info/node/45949
        #
        # 11: 1921-02-14T20:00:00 UTC+3/+1 (MSD)
        # 12: 1921-03-20T19:00:00 UTC+3/+2
        # 13: 1921-08-31T19:00:00 UTC+3/+1 (MSD)
        @test_broken tz.transitions[12] == moscow.transitions[12]
    end
end
