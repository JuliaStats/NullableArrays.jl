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


    #----- test Base.deleteat! -----#


    #----- test Base.append! -----#


    #----- test Base.sizehint! -----#


    #----- test padnull! -----#


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
