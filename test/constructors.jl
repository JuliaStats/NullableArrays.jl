module TestConstructors
    using Base.Test
    using NullableArrays

    # test Inner Constructor
    @test_throws ArgumentError NullableArray([1, 2, 3, 4], [true, false, true])

    # test Constructor #1
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

    # test Constructor #2
    dv = NullableArray(v)
    @test isa(dv, NullableVector{Int})

    y = NullableArray([1, 2, 3, 4, 5, 6])
    @test isa(y, NullableVector{Int})

    # test Constructor #3
    u1 = NullableArray(Int, (5, ))
    u2 = NullableArray(Int, (2, 2))
    u3 = NullableArray(Int, (2, 2, 2))
    @test isa(u1, NullableVector{Int})
    @test isa(u2, NullableMatrix{Int})
    @test isa(u3, NullableArray{Int, 3})

    # test Constructor #4
    x1 = NullableArray(Int, 2)
    x2 = NullableArray(Int, 2, 2)
    x3 = NullableArray(Int, 2, 2, 2)
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(x3, NullableArray{Int, 3})

    # test Constructor #5
    z = NullableArray([1, nothing, 2, nothing, 3], Int, Void)
    @test isa(z, NullableVector{Int})
    @test z.isnull[2]
    @test z.isnull[4]

    # test Constructor #6
    Z = NullableArray([1, "na", 2, 3, 4, 5, "na"], Int, "na")
    @test isa(Z, NullableVector{Int})
    @test Z.isnull == [false, true, false, false, false, false, true]

    Y = NullableArray([1, "na", 2, 3, 4, 5, "na"], Int, ASCIIString)
    @test isequal(Y, Z)

    # test Constructor #7
    @test isequal(NullableVector{Int}(), NullableArray{Int, 1}([]))
    @test isequal(NullableArray{Bool, 2}(),
                  NullableArray{Bool, 2}(Array(Bool, 0, 0)))

    # test conversion from arrays of nullables
    array_of_nulls = Nullable{Int}[Nullable(1), Nullable(2), Nullable(3), Nullable()]
    @test isa(NullableArray(array_of_nulls), NullableArray{Int,1})
    @test isequal(NullableArray(array_of_nulls), NullableArray{Int,1}([1,2,3,4],[false,false,false,true]))
    @test isa(NullableArray{Int64}(array_of_nulls), NullableArray{Int,1})
    @test isequal(NullableArray{Int64}(array_of_nulls), NullableArray{Int,1}([1,2,3,4],[false,false,false,true]))
    @test isa(NullableArray{Float64}(array_of_nulls), NullableArray{Float64,1})
    @test isequal(NullableArray{Float64}(array_of_nulls), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],[false,false,false,true]))
    @test isa(NullableArray{Int64,1}(array_of_nulls), NullableArray{Int,1})
    @test isequal(NullableArray{Int64,1}(array_of_nulls), NullableArray{Int,1}([1,2,3,4],[false,false,false,true]))
    @test isa(NullableArray{Float64,1}(array_of_nulls), NullableArray{Float64,1})
    @test isequal(NullableArray{Float64,1}(array_of_nulls), NullableArray{Float64,1}([1.0,2.0,3.0,4.0],[false,false,false,true]))
end
