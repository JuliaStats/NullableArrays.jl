module TestReduce
    using NullableArrays
    using Base.Test

    srand(1)
    f(x) = 5 * x
    f{T<:Number}(x::Nullable{T}) = ifelse(isnull(x), Nullable{typeof(5 * x.value)}(),
                                                     Nullable(5 * x.value))

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
        @test v.value ≈ mapreduce(f, +, B)
        @test !isnull(v)

        @test isequal(reduce(+, X), Nullable(reduce(+, X.values)))
        @test isequal(reduce(+, Y), Nullable{Float64}())
        v = reduce(+, Y, skipnull=true)
        @test v.value ≈ reduce(+, B)
        @test !isnull(v)

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
            @test v.value ≈ method(B)
            @test !isnull(v)
            @test isequal(method(f, Y), Nullable{Float64}())
            v = method(f, Y, skipnull=true)
            @test v.value ≈ method(f, B)
            @test !isnull(v)
        end

        @test isequal(extrema(X), (Nullable(minimum(A)), Nullable(maximum(A))))
        @test isequal(extrema(Y), (Nullable{Float64}(), Nullable{Float64}()))
        v1 = extrema(Y, skipnull=true)
        v2 = extrema(B)
        @test v1[1].value == v2[1]
        @test !isnull(v1[1])
        @test v1[2].value == v2[2]
        @test !isnull(v1[2])

        H = rand(Bool, N)
        G = H[find(x->!x, M)]
        U = NullableArray(H)
        V = NullableArray(H, M)

        for op in (
            &,
            |,
        )
            @test isequal(reduce(op, U),
                          Nullable(reduce(op, H)))
            @test isequal(reduce(op, U, skipnull=true),
                          Nullable(reduce(op, H)))
            @test isequal(reduce(op, V, skipnull=true),
                          Nullable(reduce(op, G)))
        end
    end
end
