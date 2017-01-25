module TestOperators
    using NullableArrays
    using Base.Test
    using Compat

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

    if isdefined(Base, :fieldname) && Base.fieldname(Nullable, 1) == :hasvalue # Julia 0.6
        _Nullable(x, hasvalue::Bool) = Nullable(x, hasvalue)
    else
        _Nullable(x, hasvalue::Bool) = Nullable(x, !hasvalue)
    end

    ensure_neg(x::Unsigned) = -convert(Signed, x)
    ensure_neg(x::Any) = -abs(x)

    # check for fast path (null-safe combinations of operators and types)
    if VERSION >= v"0.5.0-dev" # Some functors are missing on 0.4.0, don't check fast path
        if isdefined(Base, :uniontypes)
            testtypes = Base.uniontypes(NullableArrays.SafeTypes)
        else
            testtypes = NullableArrays.SafeTypes.types
        end
        for S in testtypes, T in testtypes
            # mixing signed and unsigned types is unsafe (slow path tested below)
            ((S <: Signed) ⊻ (T <: Signed)) && continue

            u0 = zero(S)
            u1 = one(S)
            u2 = rand(S)

            v0 = zero(T)
            v1 = one(T)
            v2 = rand(T)

            # safe unary operators
            for op in (+, -, ~, abs, abs2, cbrt)
                S <: AbstractFloat && op == (~) && continue
                # Temporary workaround until JuliaLang/julia#18803
                S === Float16 && op == cbrt && continue

                @test op(Nullable(u0)) === Nullable(op(u0))
                @test op(Nullable(u1)) === Nullable(op(u1))
                @test op(Nullable(u2)) === Nullable(op(u2))
                @test op(_Nullable(u0, false)) === _Nullable(op(u0), false)
            end

            for u in (u0, u1, u2), v in (v0, v1, v2)
                # safe binary operators: === checks that the fast-path was taken (no branch)
                for op in (+, -, *, /, &, |, >>, <<, >>>,
                           <, >, <=, >=,
                           Base.scalarmin, Base.scalarmax)
                    (T <: AbstractFloat || S <: AbstractFloat) && op in (&, |, >>, <<, >>>) && continue

                    @test op(Nullable(u), Nullable(v)) === Nullable(op(u, v))
                    @test op(_Nullable(u, false), _Nullable(v, false)) === _Nullable(op(u, v), false)
                    @test op(Nullable(u), _Nullable(v, false)) === _Nullable(op(u, v), false)
                    @test op(_Nullable(u, false), Nullable(v)) === _Nullable(op(u, v), false)
                end
            end
        end

        @test !Nullable(true) === Nullable(false)
        @test !Nullable(false) === Nullable(true)
        @test !(_Nullable(true, false)) === _Nullable(false, false)
        @test !(_Nullable(false, false)) === _Nullable(true, false)
    end

    # test all types and operators (including null-unsafe ones)
    if isdefined(Base, :uniontypes)
        testtypes = Base.uniontypes(NullableArrays.SafeTypes)
    else
        testtypes = NullableArrays.SafeTypes.types
    end
    for S in testtypes, T in testtypes
        u0 = zero(S)
        u1 = one(S)
        u2 = S <: Union{BigInt, BigFloat} ? S(rand(Int128)) : rand(S)

        v0 = zero(T)
        v1 = one(T)
        v2 = T <: Union{BigInt, BigFloat} ? T(rand(Int128)) : rand(T)

        # abs(typemin(x)) is negative (bad luck)
        abs(u2) < 0 && (u2 = S(u2 + 1))
        abs(v2) < 0 && (v2 = T(v2 + 1))

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
            x = op(_Nullable(v0, false))
            @test isa(x, Nullable{R}) && isnull(x)
            x = op(_Nullable(v1, false))
            @test isa(x, Nullable{R}) && isnull(x)
            x = op(_Nullable(v2, false))
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
        x = sqrt(_Nullable(v0, false))
        @test isa(x, Nullable{R}) && isnull(x)
        x = sqrt(_Nullable(ensure_neg(v1), false))
        @test isa(x, Nullable{R}) && isnull(x)
        x = sqrt(_Nullable(ensure_neg(v2), false))
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
                x = op(_Nullable(u, false), _Nullable(v, false))
                @test isa(x, Nullable{R}) && isnull(x)
                x = op(Nullable(u), _Nullable(v, false))
                @test isa(x, Nullable{R}) && isnull(x)
                x = op(_Nullable(u, false), Nullable(v))
                @test isa(x, Nullable{R}) && isnull(x)

                x = op(_Nullable(u, false), Nullable())
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), _Nullable(u, false))
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable())
                @test isa(x, Nullable{Union{}}) && isnull(x)
            end

            # unsafe binary operators
            # ^
            if S <: Integer && T <: Integer && u != 0 && u != 1 && v != 0
                @test_throws DomainError Nullable(u)^Nullable(ensure_neg(v))
            end
            @test isequal(Nullable(u)^Nullable(one(T)+one(T)), Nullable(u^(one(T)+one(T))))
            R = Base.promote_op(^, S, T)
            x = _Nullable(u, false)^_Nullable(-abs(v), false)
            @test isnull(x) && eltype(x) === R
            x = _Nullable(u, true)^_Nullable(-abs(v), false)
            @test isnull(x) && eltype(x) === R
            x = _Nullable(u, false)^_Nullable(-abs(v), true)
            @test isnull(x) && eltype(x) === R

            x = Nullable(u, false)^Nullable()
            @test isa(x, Nullable{S}) && isnull(x)
            x = Nullable()^_Nullable(u, false)
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
                x = op(_Nullable(u, false), _Nullable(v, false))
                @test isnull(x) && eltype(x) === R
                x = op(_Nullable(u, true), _Nullable(v, false))
                @test isnull(x) && eltype(x) === R
                x = op(_Nullable(u, false), _Nullable(v, true))
                @test isnull(x) && eltype(x) === R

                x = op(Nullable(u, false), Nullable())
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), _Nullable(u, false))
                @test isa(x, Nullable{S}) && isnull(x)
                x = op(Nullable(), Nullable())
                @test isa(x, Nullable{Union{}}) && isnull(x)
            end

            # isless
            @test isless(Nullable(u), Nullable(v)) === isless(u, v)

            @test isless(Nullable(u), _Nullable(v, false)) === true
            @test isless(_Nullable(u, false), Nullable(v)) === false
            @test isless(_Nullable(u, false), _Nullable(v, false)) === false

            @test isless(Nullable(u), Nullable()) === true
            @test isless(Nullable(), Nullable(v)) === false
            @test isless(Nullable(), Nullable()) === false
        end
    end
end
