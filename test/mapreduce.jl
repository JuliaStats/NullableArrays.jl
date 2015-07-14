module TestReduce
    using NullableArrays
    using Base.Test

    srand(1)
    A = rand(10)
    M = rand(Bool, 10)
    M[rand(1:5)] = true
    M[rand(6:10)] = false
    X = NullableArray(A)
    Y = NullableArray(A, M)
    B = A[find(x->!x, M)]
    f(x) = 5 * x
    f{T<:Number}(x::Nullable{T}) = Nullable(5 * x.value, x.isnull)

    @test isequal(mapreduce(f, +, X), Nullable(mapreduce(f, +, X.values)))
    @test isequal(mapreduce(f, +, Y), Nullable{Float64}())
    @test isequal(mapreduce(f, +, Y, skipnull=true),
                  Nullable(mapreduce(f, +, B)))

    @test isequal(reduce(+, X), Nullable(reduce(+, X.values)))
    @test isequal(reduce(+, Y), Nullable{Float64}())
    @test isequal(reduce(+, Y, skipnull=true),
                Nullable(reduce(+, B)))

    for method in (
        sum,
        prod,
        minimum,
        maximum,
    )
        @test isequal(method(X), Nullable(method(A)))
        @test isequal(method(f, X), Nullable(method(f, A)))
        @test isequal(method(Y), Nullable{Float64}())
        @test isequal(method(Y, skipnull=true), Nullable(method(B)))
        @test isequal(method(f, Y), Nullable{Float64}())
        @test isequal(method(f, Y, skipnull=true), Nullable(method(f, B)))
    end

    for method in (
        sumabs,
        sumabs2,
    )
        @test isequal(method(X), Nullable(method(A)))
        @test isequal(method(Y), Nullable{Float64}())
        @test isequal(method(Y, skipnull=true), Nullable(method(B)))
    end
end
