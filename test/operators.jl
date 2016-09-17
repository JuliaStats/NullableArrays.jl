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

    srand(1)
    ensure_neg(x::Unsigned) = -convert(Signed, x)
    ensure_neg(x::Any) = -abs(x)

    # check for fast path (null-safe combinations of operators and types)
    if VERSION >= v"0.5.0-dev" # Some functors are missing on 0.4.0, don't check fast path
        for S in NullableArrays.SafeTypes.types,
            T in NullableArrays.SafeTypes.types
            # mixing signed and unsigned types is unsafe (slow path tested below)
            ((S <: Signed) $ (T <: Signed)) && continue

            u0 = zero(S)
            u1 = one(S)
            u2 = rand(S)

            v0 = zero(T)
            v1 = one(T)
            v2 = rand(T)

            # safe unary operators
            for op in (+, -, ~, abs, abs2, cbrt)
                S <: AbstractFloat && op == (~) && continue

                @test op(Nullable(u0)) === Nullable(op(u0))
                @test op(Nullable(u1)) === Nullable(op(u1))
                @test op(Nullable(u2)) === Nullable(op(u2))
                @test op(Nullable(u0, true)) === Nullable(op(u0), true)
            end

            for u in (u0, u1, u2), v in (v0, v1, v2)
                # safe binary operators: === checks that the fast-path was taken (no branch)
                for op in (+, -, *, /, &, |, >>, <<, >>>,
                           <, >, <=, >=,
                           Base.scalarmin, Base.scalarmax)
                    (T <: AbstractFloat || S <: AbstractFloat) && op in (&, |, >>, <<, >>>) && continue

                    @test op(Nullable(u), Nullable(v)) === Nullable(op(u, v))
                    @test op(Nullable(u, true), Nullable(v, true)) === Nullable(op(u, v), true)
                    @test op(Nullable(u), Nullable(v, true)) === Nullable(op(u, v), true)
                    @test op(Nullable(u, true), Nullable(v)) === Nullable(op(u, v), true)
                end
            end
        end

        @test !Nullable(true) === Nullable(false)
        @test !Nullable(false) === Nullable(true)
        @test !(Nullable(true, true)) === Nullable(false, true)
        @test !(Nullable(false, true)) === Nullable(true, true)
    end

    # test all types and operators (including null-unsafe ones)
    for S in Union{NullableArrays.SafeTypes, BigInt, BigFloat}.types,
        T in Union{NullableArrays.SafeTypes, BigInt, BigFloat}.types
        u0 = zero(S)
        u1 = one(S)
        u2 = S <: Union{BigInt, BigFloat} ? S(rand(Int128)) : rand(S)

        v0 = zero(T)
        v1 = one(T)
        v2 = T <: Union{BigInt, BigFloat} ? T(rand(Int128)) : rand(T)

        (v2 > 5 || v2 < -5) && (v2 = T(5)) # Work around JuliaLang/julia#16989

        # safe unary operators
        for op in (+, -, ~, abs, abs2, cbrt)
            T <: AbstractFloat && op == (~) && continue

            R = Base.promote_op(op, T)
            x = op(Nullable(v0))
            @test isa(x, Nullable{R}) && isequal(x, Nullable(op(v0)))
            x = op(Nullable(v1))
            @test isa(x, Nullable{R}) && isequal(x, Nullable(op(v1)))
            x = op(Nullable(v2))
            @test isa(x, Nullable{R}) && isequal(x, Nullable(op(v2)))
            x = op(Nullable(v0, true))
            @test isa(x, Nullable{R}) && isnull(x)
            x = op(Nullable(v1, true))
            @test isa(x, Nullable{R}) && isnull(x)
            x = op(Nullable(v2, true))
            @test isa(x, Nullable{R}) && isnull(x)
            x = op(Nullable{R}())
            @test isa(x, Nullable{R}) && isnull(x)

            x = op(Nullable())
            @test isa(x, Nullable{Union{}}) && isnull(x)
        end

        # unsafe unary operators
        # sqrt
        @test_throws DomainError sqrt(Nullable(ensure_neg(v1)))
        R = Base.promote_op(sqrt, T)
        x = sqrt(Nullable(v0))
        @test isa(x, Nullable{R}) && isequal(x, Nullable(sqrt(v0)))
        x = sqrt(Nullable(v1))
        @test isa(x, Nullable{R}) && isequal(x, Nullable(sqrt(v1)))
        x = sqrt(Nullable(abs(v2)))
        @test isa(x, Nullable{R}) && isequal(x, Nullable(sqrt(abs(v2))))
        x = sqrt(Nullable(v0, true))
        @test isa(x, Nullable{R}) && isnull(x)
        x = sqrt(Nullable(ensure_neg(v1), true))
        @test isa(x, Nullable{R}) && isnull(x)
        x = sqrt(Nullable(ensure_neg(v2), true))
        @test isa(x, Nullable{R}) && isnull(x)
        x = sqrt(Nullable{R}())
        @test isa(x, Nullable{R}) && isnull(x)

        x = sqrt(Nullable())
        @test isa(x, Nullable{Union{}}) && isnull(x)

        for u in (u0, u1, u2), v in (v0, v1, v2)
            # safe binary operators
            for op in (+, -, *, /, &, |, >>, <<, >>>,
                       <, >, <=, >=,
                       Base.scalarmin, Base.scalarmax)
                (T <: AbstractFloat || S <: AbstractFloat) && op in (&, |, >>, <<, >>>) && continue
                if VERSION < v"0.5.0-dev"
                    (T <: Bool || S <: Bool) && op in (>>, <<, >>>) && continue
                    (T <: BigInt || S <: BigInt) && op in (&, |, >>, <<, >>>) && continue
                end

                if S <: Unsigned || T <: Unsigned
                    @test isequal(op(Nullable(abs(u)), Nullable(abs(v))), Nullable(op(abs(u), abs(v))))
                else
                    @test isequal(op(Nullable(u), Nullable(v)), Nullable(op(u, v)))
                end
                R = Base.promote_op(op, S, T)
                x = op(Nullable(u, true), Nullable(v, true))
                @test isa(x, Nullable{R}) && isnull(x)
                x = op(Nullable(u), Nullable(v, true))
                @test isa(x, Nullable{R}) && isnull(x)
                x = op(Nullable(u, true), Nullable(v))
                @test isa(x, Nullable{R}) && isnull(x)

                x = op(Nullable(u, true), Nullable())
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable(u, true))
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable())
                @test isa(x, Nullable{Union{}}) && isnull(x)
            end

            # unsafe binary operators
            # ^
            if S <: Integer && T <: Integer && u != 0
                @test_throws DomainError Nullable(u)^Nullable(ensure_neg(one(v)))
            end
            @test isequal(Nullable(u)^Nullable(2*one(T)), Nullable(u^(2*one(T))))
            R = Base.promote_op(^, S, T)
            x = Nullable(u, true)^Nullable(-abs(v), true)
            @test isnull(x) && eltype(x) === R
            x = Nullable(u, false)^Nullable(-abs(v), true)
            @test isnull(x) && eltype(x) === R
            x = Nullable(u, true)^Nullable(-abs(v), false)
            @test isnull(x) && eltype(x) === R

            x = Nullable(u, true)^Nullable()
            @test isa(x, Nullable{S}) && isnull(x)
            x = Nullable()^Nullable(u, true)
            @test isa(x, Nullable{S}) && isnull(x)
            x = Nullable()^Nullable()
            @test isa(x, Nullable{Union{}}) && isnull(x)

            # ÷ and %
            for op in (÷, %)
                if S <: Integer && T <: Integer && v == 0
                    @test_throws DivideError op(Nullable(u), Nullable(v))
                else
                    @test isequal(op(Nullable(u), Nullable(v)), Nullable(op(u, v)))
                end
                R = Base.promote_op(op, S, T)
                x = op(Nullable(u, true), Nullable(v, true))
                @test isnull(x) && eltype(x) === R
                x = op(Nullable(u, false), Nullable(v, true))
                @test isnull(x) && eltype(x) === R
                x = op(Nullable(u, true), Nullable(v, false))
                @test isnull(x) && eltype(x) === R

                x = op(Nullable(u, true), Nullable())
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable(u, true))
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable())
                @test isa(x, Nullable{Union{}}) && isnull(x)
            end

            # isless
            @test isless(Nullable(u), Nullable(v)) === isless(u, v)

            @test isless(Nullable(u), Nullable(v, true)) === true
            @test isless(Nullable(u, true), Nullable(v)) === false
            @test isless(Nullable(u, true), Nullable(v, true)) === false

            @test isless(Nullable(u), Nullable()) === true
            @test isless(Nullable(), Nullable(v)) === false
            @test isless(Nullable(), Nullable()) === false
        end
    end
end
