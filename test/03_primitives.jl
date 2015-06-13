module TestPrimitives
    using Base.Test
    using NullableArrays
# TODO: Organize tests, include references to /src

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


    # copy!
    function nonbits(dv)
        ret = similar(dv, Integer)
        for i = 1:length(dv)
            if !isnull(dv, i)
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
        # Base.copy! was inconsistent until recently in 0.4-dev
        da_or_04 = VERSION > v"0.4-"

        @test isequal(copy!(copy(dest), src), res1)
        @test isequal(copy!(copy(dest), 1, src), res1)

        da_or_04 && @test isequal(copy!(copy(dest), 2, src, 2), res2)
        @test isequal(copy!(copy(dest), 2, src, 2, 1), res2)

        @test isequal(copy!(copy(dest), 99, src, 99, 0), dest)

        @test isequal(copy!(copy(dest), 1, emptysrc), dest)
        da_or_04 && @test_throws BoundsError copy!(dest, 1, emptysrc, 1)

        for idx in [0, 4]
            @test_throws BoundsError copy!(dest, idx, src)
            @test_throws BoundsError copy!(dest, idx, src, 1)
            @test_throws BoundsError copy!(dest, idx, src, 1, 1)
            @test_throws BoundsError copy!(dest, 1, src, idx)
            @test_throws BoundsError copy!(dest, 1, src, idx, 1)
        end

       da_or_04 && @test_throws BoundsError copy!(dest, 1, src, 1, -1)

        @test_throws BoundsError copy!(dest, bigsrc)

        @test_throws BoundsError copy!(dest, 3, src)
        @test_throws BoundsError copy!(dest, 3, src, 1)
        @test_throws BoundsError copy!(dest, 3, src, 1, 2)
        @test_throws BoundsError copy!(dest, 1, src, 2, 2)
    end

# ----- test Base.fill! ------------------------------------------------------#

    x = NullableArray(Int, 10, 2)
    fill!(x, Nullable(10))
    y = NullableArray(Float64, 10)
    fill!(y, rand(Float64))

    @test x.values == fill(10, 10, 2)
    @test isequal(x.isnull, fill(false, 10, 2))
    @test isequal(y.isnull, fill(false, 10))

# ----- test Base.deepcopy ---------------------------------------------------#

    y1 = deepcopy(y)
    @test isequal(y1, y)
    @assert !(y === y1)

# ----- test Base.resize! ----------------------------------------------------#

    resize!(y1, 20)
    @test y1.values[1:10] == y.values[1:10]
    @test y1.isnull[1:10] == y.isnull[1:10]
    @test y1.isnull[11:20] == fill(true, 10)

    resize!(y1, 5)
    @test y1.values[1:5] == y.values[1:5]
    @test y1.isnull[1:5] == y.isnull[1:5]

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

    z = NullableArray([1, 2, 3, 'a', 5, 'b', 7, 'c'], Int, Char)
    @test dropnull(z) == [1, 2, 3, 5, 7]

# ----- test Base.isnull -----------------------------------------------------#

    @test isnull(z) == [false, false, false, true, false, true, false, true]
    @test isnull(z, 1) == false
    @test isnull(z, 4) == true
    z = NullableArray([1 nothing; nothing 4], Int, Void)
    @test isnull(z, 1, 1) == false
    @test isnull(z, 1, 2) == true
    z = NullableArray(fill(Int, 3, 3, 3))
    @test isnull(z, 1, 3, 2) == false

# ----- test anynull ---------------------------------------------------------#

    @test anynull(z) == false
    z = NullableArray(Int, 10)
    @test anynull(z) == true

# ----- test allnull ---------------------------------------------------------#

    @test allnull(z) == true
    setindex!(z, 10, 1)
    @test allnull(z) == false

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

# ----- test Base.convert ----------------------------------------------------#

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

    # The following tests concern methods that are deprecated.
    # TODO: rewrite tests once source methods have proper nomenclature

    # @test_throws NullException bool(_x)
    # @test isa(bool(NullableArray([false, true, false, true])), Vector{Bool})
    # h.isnull[1] = true
    # # @test anynull(h)
    # @test_throws NullException int(h)
    # h.isnull[1] = false
    # @test isa(int(h), Matrix{Int64})
    # @test isa(float(g), Matrix{Float64})
    # g.isnull[1] = true
    # @test_throws NullException float(g)

# ----- test Base.hash (julia/base/hashing.jl:5) -----------------------------#

    # Omitted for now, pending investigation into NullableArray-specific
    # method.
    # TODO: reinstate testing once decision whether or not to implement
    # NullableArray-specific hash method is reached.

# ----- test unique (julia/base/set.jl:107), reverse (julia/base/array.jl:639)
    x = NullableArray([1, nothing, -2, 1, nothing, 4], Int, Void)
    @assert isequal(unique(x), NullableArray([1, nothing, -2, 4], Int, Void))
    @assert isequal(unique(reverse(x)),
                    NullableArray([4, nothing, 1, -2], Int, Void))

    y = NullableArray([nothing, 2, 3, 4, nothing, 6], Int, Void)
    @assert isequal(reverse(y),
                    NullableArray([6, nothing, 4, 3, 2, nothing], Int, Void))

    # check case where only nothing occurs in final position
    @assert isequal(unique(NullableArray([1, 2, 1, nothing], Int, Void)),
                    NullableArray([1, 2, nothing], Int, Void))

end
