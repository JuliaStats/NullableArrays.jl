module TestConstructors
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, ))
    x1 = NullableArray(Int, 5)
    x2 = NullableArray(Int, 5, 2)
    y = NullableArray([1, 2, 3, 4, 5, 6])
    y2 = NullableArray([1, 2, 3, 4, 5, 6], [true, false, false, false, false ,false])

    @test isa(x, NullableVector{Int})
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(y, NullableVector{Int})
    @test isa(y2, NullableVector{Int})
    @test y2.isnull[1]


# test if any errors thrown during common constructor use-patterns
    v = [1, 2, 3, 4]
    dv = NullableArray(v, fill(false, size(v)))

    m = [1 2; 3 4]
    dm = NullableArray(m, fill(false, size(m)))

    t = Array(Int, 2, 2, 2)
    t[1:2, 1:2, 1:2] = 1
    dt = NullableArray(t, fill(false, size(t)))

    dv = NullableArray(v)
    dv = NullableArray(v, [false, false, false, false])

    dv = NullableArray(Int, 2)
    dm = NullableArray(Int, 2, 2)
    dt = NullableArray(Int, 2, 2, 2)
end
