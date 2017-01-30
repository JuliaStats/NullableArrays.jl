module TestConstructors
    using Base.Test
    using NullableArrays

    # test Inner Constructor
    @test_throws ArgumentError NullableArray([1, 2, 3, 4], [true, false, true])

    # test (A::AbstractArray, m::Array{Bool}) constructor
    v = [1, 2, 3, 4]
    dv = NullableArray(v, fill(false, size(v)))

    m = [1 2; 3 4]
    dm = NullableArray(m, fill(false, size(m)))

    t = Array{Int}(2, 2, 2)
    t[1:2, 1:2, 1:2] = 1

    dt = NullableArray(t, fill(false, size(t)))
    dv = NullableArray(v, [false, false, false, false])

    y2 = NullableArray([1, 2, 3, 4, 5, 6],
                       [true, false, false, false, false ,false])
    @test isa(y2, NullableVector{Int})
    @test y2.isnull[1]

    # test (::AbstractArray) constructor
    dv = NullableArray(v)
    @test isa(dv, NullableVector{Int})

    y = NullableArray([1, 2, 3, 4, 5, 6])
    @test isa(y, NullableVector{Int})

    z = NullableArray(1.:6.)
    @test isa(z, NullableVector{Float64})

    # test (::Type{T}, dims::Dims) constructor
    u1 = NullableArray(Int, (5, ))
    u2 = NullableArray(Int, (2, 2))
    u3 = NullableArray(Int, (2, 2, 2))
    @test isa(u1, NullableVector{Int})
    @test isa(u2, NullableMatrix{Int})
    @test isa(u3, NullableArray{Int, 3})

    # test (::Type{T}, dims::Int...) constructor
    x1 = NullableArray(Int, 2)
    x2 = NullableArray(Int, 2, 2)
    x3 = NullableArray(Int, 2, 2, 2)
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(x3, NullableArray{Int, 3})

    # test NullableArray{T}(dims::Dims)
    d1, d2 = rand(1:100), rand(1:100)
    X1 = NullableArray{Int}((d1,))
    X2 = NullableArray{Int}((d1, d2))
    @test isequal(X1, NullableArray(Array{Int}((d1,)), fill(true, (d1,))))
    @test isequal(X2, NullableArray(Array{Int}((d1, d2)), fill(true, (d1, d2))))
    for i in 1:5
        m = rand(3:5)
        dims = tuple([ rand(1:5) for i in 1:m ]...)
        X3 = NullableArray{Int}(dims)
        @test isequal(X3, NullableArray(Array{Int}(dims), fill(true, dims)))
    end

    # test NullableArray{T}(dims::Int...)
    d1, d2 = rand(1:100), rand(1:100)
    X1 = NullableArray{Int}(d1)
    X2 = NullableArray{Int}(d1, d2)
    @test isequal(X1, NullableArray(Array{Int}(d1), fill(true, d1)))
    @test isequal(X2, NullableArray(Array{Int}(d1, d2), fill(true, d1, d2)))
    for i in 1:5
        m = rand(3:5)
        dims = [ rand(1:5) for i in 1:m ]
        X3 = NullableArray{Int}(dims...)
        @test isequal(X3, NullableArray(Array{Int}(dims...), fill(true, dims...)))
    end

    # test NullableArray{T}(dims::Int...)
    d1, d2 = rand(1:100), rand(1:100)
    X1 = NullableArray{Int,1}(d1)
    X2 = NullableArray{Int,2}(d1, d2)
    @test isequal(X1, NullableArray(Array{Int,1}(d1), fill(true, d1)))
    @test isequal(X2, NullableArray(Array{Int,2}(d1, d2), fill(true, d1, d2)))
    for i in 1:5
        m = rand(3:5)
        dims = [ rand(1:5) for i in 1:m ]
        X3 = NullableArray{Int,length(dims)}(dims...)
        @test isequal(X3, NullableArray(Array{Int}(dims...), fill(true, dims...)))
    end

    # test (A::AbstractArray, ::Type{T}, ::Type{U}) constructor
    z = NullableArray([1, nothing, 2, nothing, 3], Int, Void)
    @test isa(z, NullableVector{Int})
    @test z.isnull[2]
    @test z.isnull[4]

    # test (A::AbstractArray, ::Type{T}, na::Any) constructor
    Z = NullableArray([1, "na", 2, 3, 4, 5, "na"], Int, "na")
    @test isa(Z, NullableVector{Int})
    @test Z.isnull == [false, true, false, false, false, false, true]

    Y = NullableArray([1, nothing, 2, 3, 4, 5, nothing], Int, Void)
    @test isequal(Y, Z)

    # test NullableArray{T}()
    X = NullableArray{Int}()
    @test isequal(size(X), ())

    # test conversion from arrays, arrays of nullables and NullableArrays
    miss1 = [false,false,false,false]
    miss2 = [false,false,false,true]
    for (a, miss) in zip(([1, 2, 3, 4],
                          # 1:4, # Currently does not work on 0.4, cf. JuliaLang/julia#16265
                          Nullable{Int}[Nullable(1), Nullable(2), Nullable(3), Nullable()],
                          NullableArray(Nullable{Int}[Nullable(1), Nullable(2), Nullable(3), Nullable()])),
                         (miss1, miss2, miss2))
        @test isa(NullableArray(a), NullableArray{Int,1})
        @test isequal(NullableArray(a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(NullableArray{Int}(a), NullableArray{Int,1})
        @test isequal(NullableArray{Int}(a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(NullableArray{Float64}(a), NullableArray{Float64,1})
        @test isequal(NullableArray{Float64}(a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
        @test isa(NullableArray{Int,1}(a), NullableArray{Int,1})
        @test isequal(NullableArray{Int,1}(a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(NullableArray{Float64,1}(a), NullableArray{Float64,1})
        @test isequal(NullableArray{Float64,1}(a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))

        @test isa(convert(NullableArray, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Int}, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray{Int}, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Float64}, a), NullableArray{Float64,1})
        @test isequal(convert(NullableArray{Float64}, a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
        @test isa(convert(NullableArray{Int,1}, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray{Int,1}, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Float64,1}, a), NullableArray{Float64,1})
        @test isequal(convert(NullableArray{Float64,1}, a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
    end

    # test conversion from Array{Nullable} without element type (issue #145)
    @test isa(NullableArray(Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Any})
    @test isa(NullableArray{Int}(Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Int})
    @test isa(NullableArray{Float64}(Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Float64})

    @test isa(convert(NullableArray, Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Any})
    @test isa(convert(NullableArray{Int}, Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Int})
    @test isa(convert(NullableArray{Float64}, Nullable[Nullable(1), Nullable(2), Nullable(3), Nullable()]), NullableArray{Float64})

    # converting a NullableArray to unqualified type NullableArray should be no-op
    m = rand(10:100)
    A = rand(m)
    M = rand(Bool, m)
    X = NullableArray(A, M)
    @test X === convert(NullableArray, X)
end
