module TestReduce
    using NullableArrays
    using Base.Test

    srand(1)
    f(x) = 5 * x
    f{T<:Number}(x::Nullable{T}) = Nullable(5 * x.value, x.isnull)

    for N in (10, 100)
        A = rand(N)
        M = rand(Bool, N)
        i = rand(1:N)
        M[i] = true
        j = rand(1:N)
        while j == i
            j = rand(1:N)
        end
        M[j] = false
        X = NullableArray(A)
        Y = NullableArray(A, M)
        B = A[find(x->!x, M)]

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
            v = method(Y, skipnull=true)
            @test_approx_eq v.value method(B)
            @test v.isnull == false
        end
    end
end
