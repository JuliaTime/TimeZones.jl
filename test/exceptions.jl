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
