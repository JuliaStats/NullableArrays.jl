module TestConstructors
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, ))

    @test isa(x, NullableVector{Int})
end
