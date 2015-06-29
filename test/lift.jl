module TestLift
    using NullableArrays
    using Base.Test

    f(x::Int) = 5 * x
    g(x::Int, y::Int) = x + y
    x = Nullable(5)
    y = Nullable{Int}()
    X = NullableArray([1, 2, 3, 4, 5])

    @test isequal(@^(f(x), Int), Nullable(25))
    @test isequal(@^(f(y), Int), Nullable{Int}())
    @test_throws ArgumentError eval(macroexpand(:( @^f(y) )))
    @test_throws ArgumentError eval(macroexpand(:( @^ if x > 0; f(x) end )))

    @test isequal(@^(f(X[1]) + g(x, X[1]), Int), Nullable(11))
    @test isequal(@^(f(X[1]) + g(y, X[1]), Int), Nullable{Int}())

end
