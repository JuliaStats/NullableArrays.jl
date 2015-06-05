module TestTypeDefs
    using Base.Test
    using NullableArrays

    x = NullableArray(
        [false, false, true],
        [1, 2, 3],
    )

    y = NullableArray(
        [
            false false;
            true false;
        ],
        [
            1 2;
            3 4;
        ],
    )

    @test isa(x, NullableArray{Int, 1})
    @test isa(x, NullableVector{Int})

    @test isa(y, NullableArray{Int, 2})
    @test isa(y, NullableMatrix{Int})
end
