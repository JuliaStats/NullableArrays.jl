module TestTypeDefs
    using Base.Test
    using NullableArrays

    x = NullableArray(
        [1, 2, 3],
        [false, false, true]
    )

    y = NullableArray(
        [
            1 2;
            3 4;
        ],
        [
            false false;
            true false;
        ],
    )

    @test isa(x, NullableArray{Int, 1})
    @test isa(x, NullableVector{Int})

    @test isa(y, NullableArray{Int, 2})
    @test isa(y, NullableMatrix{Int})
end
