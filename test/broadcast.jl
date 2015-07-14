module TestBroadcast
    using NullableArrays
    using Base.Test

    A = [1:10...]
    B = reshape([1:20...], 10, 2)
    C = reshape(rand(40), 10, 2, 2)

    m = rand(Bool, 10, 2)
    n = broadcast!(x -> x, Array(Bool, 10, 2, 2), m)
    U = NullableArray(A)
    V = NullableArray(B, m)
    Y = NullableArray(Float64, 10, 2)
    Z = NullableArray(Float64, 10, 2, 2)

    function f{S1, S2}(x::Nullable{S1}, y::Nullable{S2})
        return Nullable(x.value * y.value, x.isnull | y.isnull)
    end
    function f{S1, S2}(x::Nullable{S1}, y::Nullable{S2}, z::Number)
        return Nullable(x.value * y.value * z, x.isnull | y.isnull)
    end
    f{T}(x::Number, y::Nullable{T}) = Nullable(x * y.value, y.isnull)
    f{T}(x::Nullable{T}, y::Number) =return f(y, x)
    f(x, y) = x * y
    f(x, y, z) = x * y * z

    # test broadcast!
    @test isequal(broadcast!(f, Y, A, B),
                  NullableArray(broadcast(f, A, B)))
    @test isequal(broadcast!(f, Y, U, V),
                  NullableArray(broadcast(f, A, B), m))
    @test isequal(broadcast!(f, Z, A, B),
                  NullableArray(broadcast!(f, Array(Int, 10, 2, 2), A, B)))
    @test isequal(broadcast!(f, Z, U, V),
                  NullableArray(broadcast!(f, Array(Int, 10, 2, 2), A, B), n))

    # test broadcast
    @test isequal(broadcast(f, U, B),
                  NullableArray(broadcast(f, A, B)))
    @test isequal(broadcast(f, U, V),
                  NullableArray(broadcast(f, A, B), m))
    @test isequal(broadcast(f, U, V, C),
                  NullableArray(broadcast(f, A, B, C), n))

    # test broadcasted arithmetic operators
    A = rand(10)
    X1 = NullableArray(A)
    n = rand(2:5)
    dims = rand(2:5, n)
    B = rand(Float64, 10, dims...)
    X2 = NullableArray(B)
    M = rand(Bool, 10, dims...)
    Y = NullableArray(B, M)

    for op in (
        (.+),
        (.-),
        (.*),
        (./),
        (.%),
        (.^),
        (.==),
        (.!=),
        (.<),
        (.>),
        (.<=),
        (.>=),
    )
        @test isequal(op(X1, X2), NullableArray(op(A, B)))
        @test isequal(op(X1, Y), NullableArray(op(A, B), M))
    end


end # module
