module TestMap
    using Base.Test
    using NullableArrays

    N = rand(2:5)
    dims = Int[ rand(3:8) for i in 1:N ]
    m = rand(2:5)
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
    g(x::Float64...) = prod(x)

    dests = (C, Z)

    for (args, mask) in (
        ((As, Xs), ()), ((As, Ys), (R,))
    )

        # Base.map!{F}(f::F, dest::NullableArray, As::AbstractArray...;
        #              lift::Bool=false)
        map!(f, dests[1], args[1]...)
        map!(f, dests[2], args[2]...)
        @test isequal(dests[2], NullableArray(dests[1], mask...))

        map!(g, dests[1], args[1]...)
        map!(g, dests[2], args[2]...; lift=true)
        @test isequal(dests[2], NullableArray(dests[1], mask...))

        # Base.map{F}(f::F, As::NullableArray...; lift::Bool=false)
        map(f, args[1]...)
        map(f, args[2]...)
        @test isequal(dests[2], NullableArray(dests[1], mask...))

        map!(g, args[1]...)
        map!(g, args[2]...; lift=true)
        @test isequal(dests[2], NullableArray(dests[1], mask...))
    end

    for (args, masks) in (
        ((As, Xs), fill((), m)), ((As, Ys), [ (Ms[i],) for i in 1:m ])
    )
        for i in 1:m
            map!(f, args[1][i])
            map!(f, args[2][i])
            @test isequal(args[2][i], NullableArray(args[1][i], masks[i]...))

            A = map(f, args[1][i])
            X = map(f, args[2][i])
            @test isequal(X, NullableArray(A, masks[i]...))

            map!(g, args[1][i])
            map!(g, args[2][i]; lift=true)
            @test isequal(args[2][i], NullableArray(args[1][i], masks[i]...))

            A = map(f, args[1][i])
            X = map(g, args[2][i]; lift=true)
            @test isequal(X, NullableArray(A, masks[i]...))
        end
    end
end # module TestMap
