module TestReduce
    using NullableArrays
    using Base.Test
    import Base.mr_empty

    f(x) = 5 * x
    f{T<:Number}(x::Nullable{T}) = ifelse(isnull(x), Nullable{typeof(5 * x.value)}(),
                                                     Nullable(5 * x.value))
    # FIXME should Base/NullableArrays handle this automatically?
    Base.mr_empty(::typeof(f), op::typeof(+), T) = Base.r_promote(op, zero(T)::T)
    Base.mr_empty(::typeof(f), op::typeof(*), T) = Base.r_promote(op, one(T)::T)

    srand(1)
    for (N, allnull) in ((2, true), (2, false), (10, false), (2050, false))
        A = rand(N)
        if allnull
            M = fill(true, N)
        else
            M = rand(Bool, N)
            i = rand(1:N)
            # should have at least one null and at least one non-null
            M[i] = true
            j = rand(1:(N-1))
            (j == i) && (j += 1)
            M[j] = false
        end
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
            @test isequal(method(f, Y), Nullable{Float64}())
            # test skipnull=true
            if !allnull || method ∈ [sum, prod]
                # reduce
                v_r = method(Y, skipnull=true)
                @test v_r.value ≈ method(B)
                @test !isnull(v_r)
                # mapreduce
                v_mr = method(f, Y, skipnull=true)
                @test v_mr.value ≈ method(f, B)
                @test !isnull(v_mr)
            else
                # reduction over empty collection not defined for these methods
                @test_throws ArgumentError method(Y, skipnull=true)
                @test_throws ArgumentError method(f, Y, skipnull=true)
            end
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
