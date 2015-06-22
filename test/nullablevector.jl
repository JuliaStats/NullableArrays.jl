module TestNullableVector
    using NullableArrays
    using Base.Test

    A = [1:10...]
    B = [1:5...]

    X = NullableArray(A)
    Y = NullableArray(B)

    #----- test head/tail -----#
    @test isequal(head(X), NullableArray([1:6...]))
    @test isequal(tail(X), NullableArray([5:10...]))

    #----- test Base.push! -----#

    Z = NullableVector{Int}()
    push!(Z, 5)
    @test isequal(Z[1], Nullable(5))
    push!(Z, Nullable())
    @test isequal(Z, NullableArray([5, 1], [false, true]))

    #----- test Base.pop! -----#

    @test isequal(pop!(Z), Nullable{Int}())
    @test isequal(pop!(Z), Nullable(5))

    #----- test Base.unshift! -----#

    @test isequal(unshift!(X, 3), NullableArray(vcat(3, [1:10...])))
    @test isequal(unshift!(X, Nullable(2)),
                  NullableArray(vcat([2, 3], [1:10...])))
    @test isequal(unshift!(X, Nullable{Int}()),
                  NullableArray(vcat([1, 2, 3], [1:10...]),
                                vcat(true, fill(false, 12))
                  )
          )
    @test isequal(unshift!(Y, 1, Nullable(), Nullable(3)),
                  NullableArray([1, 2, 3, 1, 2, 3, 4, 5],
                                [false, true, false, false,
                                false, false, false, false]
                  )
          )

    #----- test Base.shift! -----#

    # Base.shift!{T}(X::NullableVector{T})
    Z = NullableArray([1:10...])

    @test isequal(shift!(Z), Nullable(1))
    @test isequal(Z, NullableArray([2:10...]))

    unshift!(Z, Nullable{Int}())

    @test isequal(shift!(Z), Nullable{Int}())

    #----- test Base.splice! -----#

    # Base.splice!(X::NullableVector, i::Integer, ins=_default_splice)
    X = NullableArray([1:5...])

    splice!(X, 2)
    @test isequal(X, NullableArray([1, 3, 4, 5]))

    splice!(X, 2, 4)
    @test isequal(X, NullableArray([1, 4, 4, 5]))

    splice!(X, 2, [2, 3])
    @test isequal(X, NullableArray([1:5...]))

    splice!(X, 5, [5, 6, 7])
    @test isequal(X, NullableArray([1:7...]))

    # Base.splice!{T<:Integer}(X::NullableVector,
    #                          rng::UnitRange{T},
    #                          ins=_default_splice)

    splice!(X, 1:2)
    @test isequal(X, NullableArray([3:7...]))

    splice!(X, 1:2, 4)
    @test isequal(X, NullableArray([4:7...]))

    splice!(X, 1:3, [5, 6])
    @test isequal(X, NullableArray([5, 6, 7]))

    splice!(X, 2:3, [6, 7, 8, 9, 10])
    @test isequal(X, NullableArray([5:10...]))

    #----- test Base.deleteat! -----#

    # Base.deleteat!(X::NullableArray, inds)
    X = NullableArray([1:10...])
    @test isequal(deleteat!(X, 1), NullableArray([2:10...]))

    #----- test Base.append! -----#

    # Base.append!(X::NullableVector, items::AbstractVector)
    @test isequal(append!(X, [11, 12]),
                  NullableArray([2:12...]))
    @test isequal(append!(X, [Nullable(13), Nullable(14)]),
                  NullableArray([2:14...]))
    @test isequal(append!(X, [Nullable(15), Nullable()]),
                  NullableArray([2:16...], vcat(fill(false, 14), true)))

    #----- test Base.sizehint! -----#

    # Base.sizehint!(X::NullableVector, newsz::Integer)
    sizehint!(X, 20)

    #----- test padnull! -----#

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

    #----- test Base.reverse!/Base.reverse -----#

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
    # check for case where isbits(eltype(X)) = false & anynull(X) = false
    push!(Z, Nullable())
    @test isequal(reverse!(Z),
                  unshift!(NullableArray(Array{Int, 1}[[1, 2], [3, 4], [5, 6]]),
                  Nullable()
                  )
          )

end
