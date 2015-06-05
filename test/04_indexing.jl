module TestIndexing
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, 2))

    for i in eachindex(x)
        x[i] = i
    end

    for i in eachindex(x)
        y = x[i]
        @test isa(y, Nullable{Int})
        @test get(y) === i
    end

    for i in eachindex(x)
        x[i] = Nullable{Int}()
    end

    for i in eachindex(x)
        y = x[i]
        @test isa(y, Nullable{Int})
        @test isnull(y)
    end
end
