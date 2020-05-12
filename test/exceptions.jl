using TimeZones: ParseNextError

@testset "Exceptions" begin
    # Test exception messages
    tz = VariableTimeZone(
        "Imaginary/Zone",
        [Transition(DateTime(1800,1,1), FixedTimeZone("IST",0,0))],
        DateTime(1980,1,1),
    )

    @test sprint(showerror, AmbiguousTimeError(DateTime(2015,1,1), tz)) ==
        "AmbiguousTimeError: Local DateTime 2015-01-01T00:00:00 is ambiguous within Imaginary/Zone"
    @test sprint(showerror, NonExistentTimeError(DateTime(2015,1,1), tz)) ==
        "NonExistentTimeError: Local DateTime 2015-01-01T00:00:00 does not exist within Imaginary/Zone"
    @test sprint(showerror, UnhandledTimeError(tz)) ==
        "UnhandledTimeError: TimeZone Imaginary/Zone does not handle dates on or after 1980-01-01T00:00:00 UTC"
end

@testset "ParseNextError" begin
    sshowerror(x) = sprint(showerror, x; context=:color => true)

    @test ParseNextError("", "", 1) == ParseNextError("", "", 1, 0)
    @test ParseNextError("", "A", 1) == ParseNextError("", "A", 1, 1)

    @test sshowerror(ParseNextError("", "A", 1)) == "$ParseNextError: \"\e[4mA\e[24m\""
    @test sshowerror(ParseNextError("Fail", "A", 1)) == "$ParseNextError: Fail: \"\e[4mA\e[24m\""
    @test sshowerror(ParseNextError("", "", 1)) == "$ParseNextError: \"\e[4m\"\e[24m"
    @test sshowerror(ParseNextError("", "0:A:0", 3, 3)) == "$ParseNextError: \"0:\e[4mA\e[24m:0\""

    @test sshowerror(ParseNextError("", "<>", 2, 0)) == "$ParseNextError: \"<\e[4m>\e[24m\""
    @test sshowerror(ParseNextError("", "<>", 2, 4)) == "$ParseNextError: \"<\e[4m>\e[24m\""
end
