using TimeZones: optional

function strip(ex::Expr)
    args = []
    for arg in ex.args
        if isa(arg, Expr)
            arg = strip(arg)
        end

        if !isa(arg, LineNumberNode)
            push!(args, arg)
        end
    end

    return Expr(ex.head, args...)
end

Base.isequal(a::Array{Expr}, b::Array{Expr}) = map(strip, a) == map(strip, b)



# We can include comments in our comparison here since the expressions are on the same line
@test optional(:(foo(a, b, c=3; d=4) = nothing)) == [:(foo(a, b, c=3; d=4) = nothing)]

@test isequal(
    optional(
        :(foo(a, b=2, c) = nothing)
    ),
    [
        :(foo(a, b, c) = nothing),
        :(foo(a, c) = foo(a, 2, c)),
    ],
)

@test isequal(
    optional(
        :(foo(a, b=2, c=3, d, e=5; f=6) = nothing)
    ),
    [
        :(foo(a, b, c, d, e=5; f=6) = nothing),
        :(foo(a, b, d, e=5; f=6) = foo(a, b, 3, d, e; f=f)),
        :(foo(a, d, e=5; f=6) = foo(a, 2, 3, d, e; f=f)),
    ],
)

const I = Integer
@test isequal(
    optional(
        :(function ZonedDateTime(y::I, m::I=1, d::I=1, h::I=0, mi::I=0, s::I=0, ms::I=0, tz::TimeZone)
            ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz)
        end)
    ),
    [
        :(function ZonedDateTime(y::I,m::I,d::I,h::I,mi::I,s::I,ms::I,tz::TimeZone)
            ZonedDateTime(DateTime(y,m,d,h,mi,s,ms), tz)
        end),
        :(ZonedDateTime(y::I,m::I,d::I,h::I,mi::I,s::I,tz::TimeZone) = ZonedDateTime(y,m,d,h,mi,s,0,tz)),
        :(ZonedDateTime(y::I,m::I,d::I,h::I,mi::I,tz::TimeZone) = ZonedDateTime(y,m,d,h,mi,0,0,tz)),
        :(ZonedDateTime(y::I,m::I,d::I,h::I,tz::TimeZone) = ZonedDateTime(y,m,d,h,0,0,0,tz)),
        :(ZonedDateTime(y::I,m::I,d::I,tz::TimeZone) = ZonedDateTime(y,m,d,0,0,0,0,tz)),
        :(ZonedDateTime(y::I,m::I,tz::TimeZone) = ZonedDateTime(y,m,1,0,0,0,0,tz)),
        :(ZonedDateTime(y::I,tz::TimeZone) = ZonedDateTime(y,1,1,0,0,0,0,tz)),
    ],
)

# Currently demonstrates an issue when the type given doesn't match value
# @test isequal(
#     optional(
#         :(f(a::Float64=1, b) = nothing)
#     ),
#     [
#         :(f(a::Float64, b) = nothing),
#         :(f(b) = f(1.0, b)),
#     ]
# )
