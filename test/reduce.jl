module TestReduce
    using NullableArrays
    using Base.Test

    srand(1)
    f(x) = 5 * x
    f{T<:Number}(x::Nullable{T}) = Nullable(5 * x.value, x.isnull)

    for N in (10, 2050)
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
        v = mapreduce(f, +, Y, skipnull=true)
        @test_approx_eq v.value mapreduce(f, +, B)
        @test !v.isnull

        @test isequal(reduce(+, X), Nullable(reduce(+, X.values)))
        @test isequal(reduce(+, Y), Nullable{Float64}())
        v = reduce(+, Y, skipnull=true)
        @test_approx_eq v.value reduce(+, B)
        @test !v.isnull

        for method in (
            sum,
            prod,
            minimum,
            maximum,
        )
            @test isequal(method(X), Nullable(method(A)))
            @test isequal(method(f, X), Nullable(method(f, A)))
            @test isequal(method(Y), Nullable{Float64}())
            v = method(Y, skipnull=true)
            @test_approx_eq v.value method(B)
            @test !v.isnull
            @test isequal(method(f, Y), Nullable{Float64}())
            v = method(f, Y, skipnull=true)
            @test_approx_eq v.value method(f, B)
            @test !v.isnull
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
