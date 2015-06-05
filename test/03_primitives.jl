module TestPrimitives
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, 2))

    @test isa(x, NullableMatrix{Int})

    @test size(x) === (5, 2)

    y =  similar(x, Nullable{Int}, (3, 3))

    @test isa(y, NullableMatrix{Int})

    @test size(y) === (3, 3)

    z =  similar(x, Nullable{Int}, (2,))

    @test isa(z, NullableVector{Int})

    @test size(z) === (2, )
end
