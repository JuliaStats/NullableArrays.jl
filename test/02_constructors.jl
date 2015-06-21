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

    #test Constructor #3
    u1 = NullableArray(Int, (5, ))
    u2 = NullableArray(Int, (2, 2))
    u3 = NullableArray(Int, (2, 2, 2))
    @test isa(u1, NullableVector{Int})
    @test isa(u2, NullableMatrix{Int})
    @test isa(u3, NullableArray{Int, 3})

    #test Constructor #4
    x1 = NullableArray(Int, 2)
    x2 = NullableArray(Int, 2, 2)
    x3 = NullableArray(Int, 2, 2, 2)
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(x3, NullableArray{Int, 3})

    #test Constructor #5
    z = NullableArray([1, nothing, 2, nothing, 3], Int, Void)
    @test isa(z, NullableVector{Int})
    @test z.isnull[2]
    @test z.isnull[4]
end
