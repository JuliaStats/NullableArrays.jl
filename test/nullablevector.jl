module TestNullableVector
    using NullableArrays
    using Base.Test

    A = [1:10...]
    B = [1:5...]

    X = NullableArray(A)
    Y = NullableArray(B)

    #--- head/tail
    @test isequal(head(X), NullableArray([1:6...]))
    @test isequal(tail(X), NullableArray([5:10...]))

    #--- Base.push!

    # Base.push!{T, V}(X::NullableVector{T}, v::V)
    Z = NullableVector{Int}()
    push!(Z, 5)
    @test isequal(Z[1], Nullable(5))

    # Base.push!{T, V}(X::NullableVector{T}, v::Nullable{V})
    push!(Z, Nullable())
    @test isequal(Z, NullableArray([5, 1], [false, true]))
    push!(Z, Nullable(5))
    @test isequal(Z, NullableArray([5, 1, 5], [false, true, false]))

    #--- Base.pop!

    # Base.pop!(X::NullableArray)
    @test isequal(pop!(Z), Nullable(5))
    @test isequal(pop!(Z), Nullable{Int}())
    @test isequal(pop!(Z), Nullable(5))

    #--- Base.unshift!

    # Base.unshift!(X::NullableVector, v)
    @test isequal(unshift!(X, 3), NullableArray(vcat(3, [1:10...])))

    # Base.unshift!(X::NullableVector, v::Nullable)
    @test isequal(unshift!(X, Nullable(2)),
                  NullableArray(vcat([2, 3], [1:10...])))
    @test isequal(unshift!(X, Nullable{Int}()),
                  NullableArray(vcat([1, 2, 3], [1:10...]),
                                vcat(true, fill(false, 12))
                  )
          )

    # Base.unshift!(X::NullableVector, vs...)
    @test isequal(unshift!(Y, 1, Nullable(), Nullable(3)),
                  NullableArray([1, 2, 3, 1, 2, 3, 4, 5],
                                [false, true, false, false,
                                false, false, false, false]
                  )
          )

    #--- Base.shift!

    # Base.shift!{T}(X::NullableVector{T})
    Z = NullableArray([1:10...])

    @test isequal(shift!(Z), Nullable(1))
    @test isequal(Z, NullableArray([2:10...]))

    unshift!(Z, Nullable{Int}())

    @test isequal(shift!(Z), Nullable{Int}())

    #--- test Base.splice!

    # Base.splice!(X::NullableVector, i::Integer, ins=_default_splice)
    A = [1:10...]
    B = [1:10...]
    X = NullableArray(B)

    i = rand(1:10)
    @test isequal(splice!(X, i), Nullable(splice!(A, i)))
    @test isequal(X, NullableArray(A))

    i = rand(1:9)
    j = rand(1:9)
    @test isequal(splice!(X, i, j), Nullable(splice!(A, i, j)))
    @test isequal(X, NullableArray(A))

    A = [1:10...]
    B = [1:10...]
    X = NullableArray(B)
    i = rand(1:5)
    n = rand(3:5)
    @test isequal(splice!(X, i, [1:n...]), Nullable(splice!(A, i, [1:n...])))
    @test isequal(X, NullableArray(A))

    # Base.splice!{T<:Integer}(X::NullableVector,
    #                          rng::UnitRange{T},
    #                          ins=_default_splice)

    # test with length(rng) > length(ins)
    A = [1:20...]
    B = [1:20...]
    X = NullableArray(B)
    f = rand(1:7)
    d = rand(3:5)
    l = f + d
    ins = [1, 2]
    @test isequal(splice!(X, f:l, ins),
                  NullableArray(splice!(A, f:l, ins)))
    @test isequal(X, NullableArray(A))

    i = rand(1:length(X))
    @test isequal(splice!(X, 1:i), NullableArray(splice!(A, 1:i)))

    A = [1:20...]
    B = [1:20...]
    X = NullableArray(B)
    f = rand(10:15)
    d = rand(3:5)
    l = f + d
    ins = [1, 2]
    @test isequal(splice!(X, f:l, ins),
                  NullableArray(splice!(A, f:l, ins)))
    @test isequal(X, NullableArray(A))

    # test with length(rng) < length(ins)
    A = [1:20...]
    B = [1:20...]
    X = NullableArray(B)
    f = rand(1:7)
    d = rand(3:5)
    l = f + d
    ins = [1, 2, 3, 4, 5, 6, 7]
    @test isequal(splice!(X, f:l, ins),
                  NullableArray(splice!(A, f:l, ins)))
    @test isequal(X, NullableArray(A))

    A = [1:20...]
    B = [1:20...]
    X = NullableArray(B)
    f = rand(10:15)
    d = rand(3:5)
    l = f + d
    ins = [1, 2, 3, 4, 5, 6, 7]
    @test isequal(splice!(X, f:l, ins),
                  NullableArray(splice!(A, f:l, ins)))
    @test isequal(X, NullableArray(A))

    #--- test Base.deleteat!

    # Base.deleteat!(X::NullableArray, inds)
    X = NullableArray([1:10...])
    @test isequal(deleteat!(X, 1), NullableArray([2:10...]))

    #--- test Base.append!

    # Base.append!(X::NullableVector, items::AbstractVector)
    @test isequal(append!(X, [11, 12]),
                  NullableArray([2:12...]))
    @test isequal(append!(X, [Nullable(13), Nullable(14)]),
                  NullableArray([2:14...]))
    @test isequal(append!(X, [Nullable(15), Nullable()]),
                  NullableArray([2:16...], vcat(fill(false, 14), true)))

    #--- test Base.sizehint!

    # Base.sizehint!(X::NullableVector, newsz::Integer)
    sizehint!(X, 20)

    #--- test padnull!

    # padnull!{T}(X::NullableVector{T}, front::Integer, back::Integer)
    X = NullableArray([1:5...])
    padnull!(X, 2, 3)
    @test length(X.values) == 10
    @test X.isnull == vcat(true, true, fill(false, 5), true, true, true)

    # padnull(X::NullableVector, front::Integer, back::Integer)
    X = NullableArray([1:5...])
    Y = padnull(X, 2, 3)
    @test length(Y.values) == 10
    @test Y.isnull == vcat(true, true, fill(false, 5), true, true, true)

    #--- test Base.reverse!/Base.reverse

    y = NullableArray([nothing, 2, 3, 4, nothing, 6], Int, Void)
    @assert isequal(reverse(y),
                    NullableArray([6, nothing, 4, 3, 2, nothing], Int, Void))

    # check case where only nothing occurs in final position
    @assert isequal(unique(NullableArray([1, 2, 1, nothing], Int, Void)),
                    NullableArray([1, 2, nothing], Int, Void))

    # Base.reverse!(X::NullableVector, s=1, n=length(X))
    # check for case where isbits(eltype(X)) = false
    Z = NullableArray(Array{Int, 1}[[1, 2], [3, 4], [5, 6]])
    @test isequal(reverse!(Z),
                  NullableArray(Array{Int, 1}[[5, 6], [3, 4], [1, 2]]))

    # Base.reverse!(X::NullableVector, s=1, n=length(X))
    # check for case where isbits(eltype(X)) = false & anynull(X) = true
    A = fill([1,2], 20)
    Z = NullableArray(Array{Int, 1}, 20)
    i = rand(4:8)
    for i in [i-1, i, i+1, 20 - (i + 2), 20 - (i - 1)]
        Z[i] = [1, 2]
    end
    vals = Z.values
    nulls = Z.isnull
    @test isequal(reverse!(Z), NullableArray(A, reverse!(Z.isnull)))
end
