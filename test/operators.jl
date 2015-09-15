module TestOperators
    using NullableArrays
    using Base.Test

    A = rand(10) .+ fill(1, 10)
    B = rand(10) .+ fill(1, 10)
    M = rand(Bool, 10)
    i = rand(1:10)
    j = rand(1:10)
    while j == i
        j = rand(1:10)
    end
    M[i] = true
    M[j] = false
    U = NullableArray(A)
    V = NullableArray(A, M)
    X = NullableArray(B)
    Y = NullableArray(B, M)

    # 1-ary ops
    for op in (
        +,
        -,
        # ~,
        sqrt,
    )
        v = rand(1:1_000)
        x = op(Nullable(v))
        @test_approx_eq x.value op(v)
        @test !x.isnull
        @test_throws ErrorException op(Nullable(rand(Int, 1)))
    end

    # 2-ary arithmetic/comparison ops
    for op in (
        +,
        -,
        *,
        /,
        %,
        ^,
        >,
        <,
    )
        v, w = rand(1:10), rand(1:10)
        x = op(Nullable(v), Nullable(w))
        @test_approx_eq x.value op(v, w)
        @test !x.isnull
        @test_throws ErrorException op(Nullable(rand(1)), Nullable(rand(1)))
    end

    # 2-ary logical ops
    for op in (
        &,
        |,
    )
        v, w = rand(Bool), rand(Bool)
        x = op(Nullable(v), Nullable(w))
        @test_approx_eq x.value op(v, w)
        @test !x.isnull
        @test_throws ErrorException op(Nullable(rand(Bool, 1)), Nullable(rand(Bool, 1)))
    end

    # 2-ary bitwise ops
    for op in (
        <<,
        >>,
    )
        v, w = rand(1:10), rand(1:10)
        x = op(Nullable(v), Nullable(w))
        @test_approx_eq x.value op(v, w)
        @test !x.isnull
        @test_throws ErrorException op(Nullable(rand(Int, 1)), Nullable(rand(Int, 1)))
    end
end
