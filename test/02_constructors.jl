module TestConstructors
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, ))
    x1 = NullableArray(Int, 5)
    x2 = NullableArray(Int, 5, 2)
    y = NullableArray([1, 2, 3, 4, 5, 6])
    y1 = NullableArray([1, 2, 3, 4, 5, 6], [true, false, false, false, false ,false])
    y2 = NullableArray([true, false, false, false, false ,false], [1, 2, 3, 4, 5, 6])

    @test isa(x, NullableVector{Int})
    @test isa(x1, NullableVector{Int})
    @test isa(x2, NullableMatrix{Int})
    @test isa(y, NullableVector{Int})
    @test isa(y1, NullableVector{Int})
    @test y1.isnull[1]
    @test isa(y2, NullableVector{Int})
    @test y2.isnull[1]
end
