module TestPrimitives
    using Base.Test
    using NullableArrays
    using Compat.view

    n = rand(1:5)
    siz = [ rand(2:5) for i in n ]
    A = rand(siz...)
    M = rand(Bool, siz...)
    X = NullableArray(A, M)
    i = rand(1:length(X))
    @test values(X, i) == X.values[i]
    @test isnull(X, i) == X.isnull[i]
    I = [ rand(1:size(X,i)) for i in 1:n ]
    @test values(X, I...) == X.values[I...]
    @test isnull(X, I...) == X.isnull[I...]

# ----- test Base.similar, Base.size  ----------------------------------------#

    x = NullableArray(Int, (5, 2))
    @test isa(x, NullableMatrix{Int})
    @test size(x) === (5, 2)

    y = similar(x, Nullable{Int}, (3, 3))
    @test isa(y, NullableMatrix{Int})
    @test size(y) === (3, 3)

    z = similar(x, Nullable{Int}, (2,))
    @test isa(z, NullableVector{Int})
    @test size(z) === (2, )

    # test common use-patterns for 'similar'
    dv = NullableArray(Int, 2)
    dm = NullableArray(Int, 2, 2)
    dt = NullableArray(Int, 2, 2, 2)

    similar(dv)
    similar(dm)
    similar(dt)

    similar(dv, 2)
    similar(dm, 2, 2)
    similar(dt, 2, 2, 2)

# ----- test Base.copy/Base.copy! --------------------------------------------#

    #copy
    x = NullableArray([1, 2, nothing], Int, Void)
    y = NullableArray([3, nothing, 5], Int, Void)
    @test isequal(copy(x), x)
    @test isequal(copy!(y, x), x)

    # ensure that the parent field is copied as well
    str = "something"
    x = NullableArray([pointer(str), pointer(str, 5)], [false, false], Vector{UInt8}(str))
    y = copy(x)
    @test isequal(y, x)
    @test isequal(String(y.parent), str)
    @test y.parent === x.parent

    # copy!
    function nonbits(dv)
        ret = similar(dv, Integer)
        for i = 1:length(dv)
            if !dv.isnull[i]
                ret[i] = dv[i]
            end
        end
        ret
    end
    set1 = Any[NullableArray([1, nothing, 3], Int, Void),
               NullableArray([nothing, 5], Int, Void),
               NullableArray([1, 2, 3, 4, 5], Int, Void),
               NullableArray(Int[]),
               NullableArray([nothing, 5, 3], Int, Void),
               NullableArray([1, 5, 3], Int, Void)]
    set2 = map(nonbits, set1)

    for (dest, src, bigsrc, emptysrc, res1, res2) in Any[set1, set2]
        @test isequal(copy!(copy(dest), src), res1)
        @test isequal(copy!(copy(dest), 1, src), res1)

        @test isequal(copy!(copy(dest), 2, src, 2), res2)
        @test isequal(copy!(copy(dest), 2, src, 2, 1), res2)

        @test isequal(copy!(copy(dest), 99, src, 99, 0), dest)

        @test isequal(copy!(copy(dest), 1, emptysrc), dest)
        @test_throws BoundsError copy!(dest, 1, emptysrc, 1)

        for idx in [0, 4]
            @test_throws BoundsError copy!(dest, idx, src)
            @test_throws BoundsError copy!(dest, idx, src, 1)
            @test_throws BoundsError copy!(dest, idx, src, 1, 1)
            @test_throws BoundsError copy!(dest, 1, src, idx)
            @test_throws BoundsError copy!(dest, 1, src, idx, 1)
        end

        if VERSION >= v"0.5.0-dev"
            @test_throws ArgumentError copy!(dest, 1, src, 1, -1)
        else
            @test_throws BoundsError copy!(dest, 1, src, 1, -1)
        end

        @test_throws BoundsError copy!(dest, bigsrc)

        @test_throws BoundsError copy!(dest, 3, src)
        @test_throws BoundsError copy!(dest, 3, src, 1)
        @test_throws BoundsError copy!(dest, 3, src, 1, 2)
        @test_throws BoundsError copy!(dest, 1, src, 2, 2)
    end

# ----- test Base.fill! ------------------------------------------------------#

    X = NullableArray(Int, 10, 2)
    fill!(X, Nullable(10))
    Y = NullableArray(Float64, 10)
    fill!(Y, rand(Float64))

    @test X.values == fill(10, 10, 2)
    @test isequal(X.isnull, fill(false, 10, 2))
    @test isequal(Y.isnull, fill(false, 10))

    fill!(X, Nullable())
    @test isequal(X.isnull, fill(true, 10, 2))

# ----- test Base.deepcopy ---------------------------------------------------#

    Y1 = deepcopy(Y)
    @test isequal(Y1, Y)
    @assert !(Y === Y1)

# ----- test Base.resize! ----------------------------------------------------#

    resize!(Y1, 20)
    @test Y1.values[1:10] == Y.values[1:10]
    @test Y1.isnull[1:10] == Y.isnull[1:10]
    @test Y1.isnull[11:20] == fill(true, 10)

    resize!(Y1, 5)
    @test Y1.values[1:5] == Y.values[1:5]
    @test Y1.isnull[1:5] == Y.isnull[1:5]

# ----- test Base.reshape ----------------------------------------------------#

    Y1 = reshape(copy(Y), length(Y), 1)
    @test size(Y1) == (length(Y), 1)
    @test all(i->isequal(Y1[i], Y[i]), 1:length(Y))
    Y2 = reshape(Y1, 1, length(Y1))
    @test size(Y2) == (1, length(Y1))
    @test all(i->isequal(Y1[i], Y2[i]), 1:length(Y2))
    # Test that arrays share the same data
    Y2.values[1] += 1
    Y2.isnull[2] = true
    @test all(i->isequal(Y1[i], Y2[i]), 1:length(Y2))

# ----- test Base.ndims ------------------------------------------------------#

    for n in 1:4
        @test ndims(NullableArray(Int, collect(1:n)...)) == n
    end

# ----- test Base.length -----------------------------------------------------#

    @test length(NullableArray(Int, 10)) == 10
    @test length(NullableArray(Int, 5, 5)) == 25
    @test length(NullableArray(Int, (3, 3, 3))) == 27

# ----- test Base.endof ------------------------------------------------------#

    @test endof(NullableArray(collect(1:10))) == 10
    @test endof(NullableArray([1, 2, nothing, 4, nothing])) == 5

# ----- test Base.find -------------------------------------------------------#

    z = NullableArray(rand(Bool, 10))
    @test find(z) == find(z.values)

    z = NullableArray([false, true, false, true, false, true])
    @test isequal(find(z), [2, 4, 6])

# ----- test dropnull --------------------------------------------------------#

    # dropnull(X::NullableVector)
    z = NullableArray([1, 2, 3, 'a', 5, 'b', 7, 'c'], Int, Char)
    @test dropnull(z) == [1, 2, 3, 5, 7]

    # dropnull(X::AbstractVector)
    A = Any[1, 2, 3, Nullable(), 5, Nullable(), 7, Nullable()]
    @test dropnull(A) == [1, 2, 3, 5, 7]

    # dropnull(X::AbstractVector{<:Nullable})
    B = [1, 2, 3, Nullable(), 5, Nullable(), 7, Nullable()]
    @test dropnull(B) == [1, 2, 3, 5, 7]
    # assert dropnull returns copy for !(Nullable <: eltype(X))
    nullfree = [1, 2, 3, 4]
    returned_copy = dropnull(nullfree)
    @test nullfree == returned_copy && !(nullfree === returned_copy)

# ----- test dropnull! -------------------------------------------------------#

    # for each, assert returned values are unwrapped and inplace change
    # dropnull!(X::NullableVector)
    @test dropnull!(z) == [1, 2, 3, 5, 7]
    @test isequal(z, NullableArray([1, 2, 3, 5, 7]))

    # dropnull!(X::AbstractVector)
    @test dropnull!(A) == [1, 2, 3, 5, 7]
    @test isequal(A, Any[1, 2, 3, 5, 7])

    # dropnull!(X::AbstractVector{<:Nullable})
    @test dropnull!(B) == [1, 2, 3, 5, 7]
    @test isequal(B, Nullable[1, 2, 3, 5, 7])

    # when no nulls present, dropnull! returns input vector
    returned_view = dropnull!(nullfree)
    @test nullfree == returned_view && nullfree === returned_view

    # test that dropnull! returns unwrapped values when nullables are present
    X = [false, 1, :c, "string", Nullable("I am not null"), Nullable()]
    @test !any(x -> isa(x, Nullable), dropnull!(X))
    @test any(x -> isa(x, Nullable), X)
    Y = Any[false, 1, :c, "string", Nullable("I am not null"), Nullable()]
    @test !any(x -> isa(x, Nullable), dropnull!(Y))
    @test any(x -> isa(x, Nullable), Y)

# ----- test any(isnull, X) --------------------------------------------------#

    # any(isnull, X::NullableArray)
    z = NullableArray([1, 2, 3, 'a', 5, 'b', 7, 'c'], Int, Char)
    @test any(isnull, z) == true
    @test any(isnull, dropnull(z)) == false
    z = NullableArray(Int, 10)
    @test any(isnull, z) == true

    # any(isnull, A::AbstractArray)
    A2 = [Nullable(1), Nullable(2), Nullable(3)]
    @test any(isnull, A2) == false
    push!(A2, Nullable{Int}())
    @test any(isnull, A2) == true

    # any(isnull, xs::NTuple)
    @test any(isnull, (Nullable(1), Nullable(2))) == false
    @test any(isnull, (Nullable{Int}(), Nullable(1), 3, 6)) == true

    # any(isnull, S::SubArray{T, N, U<:NullableArray})
    A = rand(10, 3, 3)
    M = rand(Bool, 10, 3, 3)
    X = NullableArray(A, M)
    i, j = rand(1:3), rand(1:3)
    S = view(X, :, i, j)

    @test any(isnull, S) == any(isnull, X[:, i, j])
    X = NullableArray(A)
    S = view(X, :, i, j)
    @test any(isnull, S) == false


# ----- test all(isnull, X) --------------------------------------------------#

    # all(isnull, X::NullableArray)
    z = NullableArray(Int, 10)
    @test all(isnull, z) == true
    z[1] = 10
    @test all(isnull, z) == false

    # all(isnull, X::AbstractArray{<:Nullable})
    @test all(isnull, Nullable{Int}[Nullable(), Nullable()]) == true
    @test all(isnull, Nullable{Int}[Nullable(1), Nullable()]) == false

    # all(isnull, X::Any)
    @test all(isnull, Any[Nullable(), Nullable()]) == true
    @test all(isnull, [1, 2]) == false
    @test all(isnull, 1:3) == false

# ----- test Base.isnan ------------------------------------------------------#

    x = NullableArray([1, 2, NaN, 4, 5, NaN, Inf, nothing], Float64, Void)
    _x = isnan(x)
    @test isequal(_x, NullableArray([false, false, true, false,
                                    false, true, false, nothing], Bool, Void))
    @test _x.isnull[8] == true

# ----- test Base.isfinite ---------------------------------------------------#

    _x = isfinite(x)
    @test isequal(_x, NullableArray([true, true, false, true,
                                    true, false, false, nothing], Bool, Void))
    @test _x.isnull[8] == true

# ----- test conversion methods ----------------------------------------------#

    u = NullableArray(collect(1:10))
    v = NullableArray(Int, 4, 4)
    fill!(v, 4)
    w = NullableArray(['a', 'b', 'c', 'd', 'e', 'f', nothing], Char, Void)
    x = NullableArray([(i, j, k) for i in 1:10, j in 1:10, k in 1:10])
    y = NullableArray([2, 4, 6, 8, 10])
    z = NullableArray([i*j for i in 1:10, j in 1:10])
    _z = NullableArray(reshape(collect(1:100), 10, 10),
                       convert(Array{Bool},
                              reshape([mod(j, 2) for i in 1:10, j in 1:10],
                                     (10, 10))))
    _x = NullableArray([false, true, false, nothing, false, true, nothing],
                      Bool, Void)
    a = [i*j*k for i in 1:2, j in 1:2, k in 1:2]
    b = collect(1:10)
    c = [i for i in 1:10, j in 1:10]

    e = convert(NullableArray, a)
    f = convert(NullableArray{Float64}, b)
    g = convert(NullableArray, c)
    h = convert(NullableArray{Float64}, g)

    @test_throws NullException convert(Array{Char, 1}, w)
    @test convert(Array{Char, 1},
                  NullableArray(dropnull(w))) == ['a', 'b', 'c', 'd', 'e', 'f']
    @test_throws NullException convert(Array{Char}, w)
    @test convert(Array{Float64}, u) == Float64[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    @test convert(Vector{Float64}, y) == Float64[2, 4, 6, 8, 10]
    @test convert(Matrix{Float64}, z) == Float64[i*j for i in 1:10, j in 1:10]
    @test_throws NullException convert(Array, w)
    @test convert(Array, v) == [4 4 4 4; 4 4 4 4; 4 4 4 4; 4 4 4 4]
    @test convert(Array, z) == [i*j for i in 1:10, j in 1:10]
    @test convert(Array, u) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    @test convert(Array, _x, false) == [false, true, false, false,
                                       false, true, false]
    @test convert(Array{Int, 1}, _x, 0) == [0, 1, 0, 0, 0, 1, 0]
    @test convert(Vector, _x, false) == [false, true, false, false,
                                        false, true, false]
    @test sum(convert(Matrix, _z, 0)) == 2775
    @test isequal(e[:, :, 1], NullableArray([1 2; 2 4]))
    @test isequal(f, NullableArray(Float64[i for i in 1:10]))
    @test isa(g, NullableArray{Int, 2})
    @test isa(h, NullableArray{Float64, 2})

    # Base.convert{T}(::Type{Vector}, X::NullableVector{T})
    X = NullableArray([1, 2, 3, 4, 5])
    @test convert(Vector, X) == [1, 2, 3, 4, 5]
    push!(X, Nullable())
    @test_throws NullException convert(Vector, X)

    # Base.convert{T}(::Type{Matrix}, X::NullableMatrix{T})
    Y = NullableArray([1 2; 3 4; 5 6; 7 8; 9 10])
    @test convert(Matrix, Y) == [1 2; 3 4; 5 6; 7 8; 9 10]
    Z = NullableArray([1 2; 3 4; 5 6; 7 8; 9 nothing], Int, Void)
    @test_throws NullException convert(Matrix, Z)

    # float(X::NullableArray)
    A = rand(Int, 20)
    M = rand(Bool, 20)
    X = NullableArray(A, M)
    @test isequal(float(X), NullableArray(float(A), M))

# ----- test Base.hash (julia/base/hashing.jl:5) -----------------------------#

    # Omitted for now, pending investigation into NullableArray-specific
    # method.
    # TODO: reinstate testing once decision whether or not to implement
    # NullableArray-specific hash method is reached.

# ----- test unique (julia/base/set.jl:107) ----------------------------------#

    x = NullableArray([1, nothing, -2, 1, nothing, 4], Int, Void)
    @assert isequal(unique(x), NullableArray([1, nothing, -2, 4], Int, Void))
    @assert isequal(unique(reverse(x)),
                    NullableArray([4, nothing, 1, -2], Int, Void))


end
