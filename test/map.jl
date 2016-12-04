module TestMap
    using Base.Test
    using NullableArrays

    # create m random arrays each with N dimensions and length dims[i] along
    # dimension i for i=1:N
    N = rand(2:5)
    dims = Int[ rand(3:8) for i in 1:N ]
    m = rand(3:5)
    As = [ rand(dims...) for i in 1:m ]

    Ms = [ rand(Bool, dims...) for i in 1:m ]
    Xs = Array{NullableArray{Float64, N}, 1}()
    for i in 1:m
        push!(Xs, NullableArray(As[i]))
    end
    Ys = Array{NullableArray{Float64, N}, 1}()
    for i in 1:m
        push!(Ys, NullableArray(As[i], Ms[i]))
    end

    C = Array(Float64, dims...)
    Z = NullableArray(Float64, dims...)

    R = map(|, Ms...)

    f(x...) = sum(x)
    dests = (C, Z)

    # 1 arg
    for (args, masks) in (
        ((As, Xs), fill((), m)), ((As, Ys), [ (Ms[i],) for i in 1:m ])
    )
        for i in 1:m
            # map!
            map!(f, args[1][i]) # map!(f, As[i])
            map!(f, args[2][i]) # map!(f, Xs[i])
            @test isequal(args[2][i], NullableArray(args[1][i], masks[i]...))
            # map
            A = map(f, args[1][i])
            X = map(f, args[2][i])
            @test isequal(X, NullableArray(A, masks[i]...))
        end
    end
    # 2 arg
    i, j = rand(1:m), rand(1:m)
    S = map(|, Ms[i], Ms[j])
    for (args, mask) in (
        ((As, Xs), ()), ((As, Ys), (S,))
    )
        # map!
        map!(f, dests[1], args[1][i], args[1][j])
        map!(f, dests[2], args[2][i], args[2][j])
        @test isequal(dests[2], NullableArray(dests[1], mask...))
        # map
        map(f, args[1][i], args[1][j])
        map(f, args[2][i], args[2][j])
        @test isequal(dests[2], NullableArray(dests[1], mask...))
    end
    # n arg
    for (args, mask) in (
        ((As, Xs), ()), ((As, Ys), (R,))
    )
        # map!
        map!(f, dests[1], args[1]...)
        map!(f, dests[2], args[2]...)
        @test isequal(dests[2], NullableArray(dests[1], mask...))
        # map
        map(f, args[1]...)
        map(f, args[2]...)
        @test isequal(dests[2], NullableArray(dests[1], mask...))
    end

    # test map over empty NullableArrays
    X = NullableArray(Int[])
    h1(x) = 5.0*x
    h2(x) = x
    h2(x...) = prod(x)

    Z1 = map(h1, X)
    Z2 = map(h2, X)
    @test isempty(Z1)
    if VERSION >= v"0.6.0-dev"
        @test isa(Z1, NullableArray{Float64})
    end
    @test isempty(Z2)
    if VERSION >= v"0.6.0-dev"
        @test isa(Z2, NullableArray{Int})
    end

    # if a function has no method for inner eltype of empty NullableArray,
    # result should be empty NullableArray{Any}() for consistency with generic map()
    h3(x::Float64...) = prod(x)
    Z3 = map(h3, X)
    @test isempty(Z3)
    @test isa(Z3, NullableArray{Any})
    Z3 = map(h3, X, X)
    @test isempty(Z3)
    @test isa(Z3, NullableArray{Any})
    Z3 = map(h3, X, X, X)
    @test isempty(Z3)
    @test isa(Z3, NullableArray{Any})

    # test map over all null NullableArray
    n = rand(10:100)
    Ys = [ NullableArray(rand(Int, n), fill(true, n)) for i in 1:rand(3:5) ]

    Z2 = map(h2, Ys[1])
    @test isequal(Z2, NullableArray(Int, n))
    if VERSION >= v"0.6.0-dev"
        @test isa(Z2, NullableArray{Int})
    end
    Z2 = map(h2, Ys[1], Ys[2])
    @test isequal(Z2, NullableArray(Int, n))
    if VERSION >= v"0.6.0-dev"
        @test isa(Z2, NullableArray{Int})
    end
    Z2 = map(h2, Ys...)
    @test isequal(Z2, NullableArray(Int, n))
    if VERSION >= v"0.6.0-dev"
        @test isa(Z2, NullableArray{Int})
    end
end # module TestMap
