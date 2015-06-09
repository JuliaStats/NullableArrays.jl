module TestPrimitives
    using Base.Test
    using NullableArrays
    # TODO: Organize tests, include references to /src

    x = NullableArray(Int, (5, 2))

    @test isa(x, NullableMatrix{Int})

    @test size(x) === (5, 2)

    y =  similar(x, Nullable{Int}, (3, 3))

    @test isa(y, NullableMatrix{Int})

    @test size(y) === (3, 3)

    z =  similar(x, Nullable{Int}, (2,))

    @test isa(z, NullableVector{Int})

    @test size(z) === (2, )

    macro nullable(vec)
        e_array = Expr(:vect)
        e_mask = Expr(:vect)
        e_target = Expr(:call, :NullableArray)
        for (i, arg) in enumerate(vec.args)
            if arg == :nothing
                push!(e_mask.args, true)
                push!(e_array.args, 0)
            else
                push!(e_mask.args, false)
                push!(e_array.args, arg)
            end
        end
        push!(e_target.args, e_mask, e_array)
        return e_target
    end

    v = [1, 2, 3, 4]
    dv = NullableArray(fill(false, size(v)), v)

    m = [1 2; 3 4]
    dm = NullableArray(fill(false, size(m)), m)

    t = Array(Int, 2, 2, 2)
    t[1:2, 1:2, 1:2] = 1
    dt = NullableArray(fill(false, size(t)), t)

    dv = NullableArray(v)
    dv = NullableArray([false, false, false, false], v)

    dv = NullableArray(Int, 2)
    dm = NullableArray(Int, 2, 2)
    dt = NullableArray(Int, 2, 2, 2)

    similar(dv)
    similar(dm)
    similar(dt)

    similar(dv, 2)
    similar(dm, 2, 2)
    similar(dt, 2, 2, 2)

    x = @nullable [1, 2, nothing]
    y = @nullable [3, nothing, 5]
    @test isequal(copy(x), x)
    @test isequal(copy!(y, x), x)

    x = @nullable [1, nothing, -2, 1, nothing, 4]
    @assert isequal(unique(x), @nullable [1, nothing, -2, 4])
    @assert isequal(unique(reverse(x)), @nullable [4, nothing, 1, -2])

    # check case where only nothing occurs in final position
    @assert isequal(unique(@nullable [1, 2, 1, nothing]), @nullable [1, 2, nothing])

    # Test copy!
    function nonbits(dv)
        ret = similar(dv, Integer)
        for i = 1:length(dv)
            if !isnull(dv, i)
                ret[i] = dv[i]
            end
        end
        ret
    end
    set1 = Any[@nullable([1, nothing, 3]),
               @nullable([nothing, 5]), @nullable([1, 2, 3, 4, 5]), NullableArray(Int[]),
               @nullable([nothing, 5, 3]), @nullable([1, 5, 3])]
    set2 = map(nonbits, set1)

    for (dest, src, bigsrc, emptysrc, res1, res2) in Any[set1, set2]
        # Base.copy! was inconsistent until recently in 0.4-dev
        da_or_04 = VERSION > v"0.4-"

        @test isequal(copy!(copy(dest), src), res1)
        @test isequal(copy!(copy(dest), 1, src), res1)

        da_or_04 && @test isequal(copy!(copy(dest), 2, src, 2), res2)
        @test isequal(copy!(copy(dest), 2, src, 2, 1), res2)

        @test isequal(copy!(copy(dest), 99, src, 99, 0), dest)

        @test isequal(copy!(copy(dest), 1, emptysrc), dest)
        da_or_04 && @test_throws BoundsError copy!(dest, 1, emptysrc, 1)

        for idx in [0, 4]
            @test_throws BoundsError copy!(dest, idx, src)
            @test_throws BoundsError copy!(dest, idx, src, 1)
            @test_throws BoundsError copy!(dest, idx, src, 1, 1)
            @test_throws BoundsError copy!(dest, 1, src, idx)
            @test_throws BoundsError copy!(dest, 1, src, idx, 1)
        end

       da_or_04 && @test_throws BoundsError copy!(dest, 1, src, 1, -1)

        @test_throws BoundsError copy!(dest, bigsrc)

        @test_throws BoundsError copy!(dest, 3, src)
        @test_throws BoundsError copy!(dest, 3, src, 1)
        @test_throws BoundsError copy!(dest, 3, src, 1, 2)
        @test_throws BoundsError copy!(dest, 1, src, 2, 2)
    end

end
