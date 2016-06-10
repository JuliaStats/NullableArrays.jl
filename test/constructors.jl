module TestConstructors
    using Base.Test, Compat
    using NullableArrays

    # test Inner Constructor
    @test_throws ArgumentError NullableArray([1, 2, 3, 4], [true, false, true])

    # test (A::AbstractArray, m::Array{Bool}) constructor
    v = [1, 2, 3, 4]
    dv = NullableArray(v, fill(false, size(v)))

    m = [1 2; 3 4]
    dm = NullableArray(m, fill(false, size(m)))

    t = Array(Int, 2, 2, 2)
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

    # test (::Type{T}, dims::Dims...) constructor
    x1 = NullableArray(Int, 2)
    x2 = NullableArray(Int, 2, 2)
    x3 = NullableArray(Int, 2, 2, 2)
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(x3, NullableArray{Int, 3})

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

    # test parameterized type constructor with no arguments
    @test isequal(NullableVector{Int}(), NullableArray{Int, 1}([]))
    @test isequal(NullableArray{Bool, 2}(),
                  NullableArray{Bool, 2}(Array(Bool, 0, 0)))

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
        @test isa(NullableArray{Int64}(a), NullableArray{Int,1})
        @test isequal(NullableArray{Int64}(a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(NullableArray{Float64}(a), NullableArray{Float64,1})
        @test isequal(NullableArray{Float64}(a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
        @test isa(NullableArray{Int64,1}(a), NullableArray{Int,1})
        @test isequal(NullableArray{Int64,1}(a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(NullableArray{Float64,1}(a), NullableArray{Float64,1})
        @test isequal(NullableArray{Float64,1}(a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))

        @test isa(convert(NullableArray, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Int64}, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray{Int64}, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Float64}, a), NullableArray{Float64,1})
        @test isequal(convert(NullableArray{Float64}, a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
        @test isa(convert(NullableArray{Int64,1}, a), NullableArray{Int,1})
        @test isequal(convert(NullableArray{Int64,1}, a), NullableArray{Int,1}([1,2,3,4],miss))
        @test isa(convert(NullableArray{Float64,1}, a), NullableArray{Float64,1})
        @test isequal(convert(NullableArray{Float64,1}, a), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],miss))
    end
end
