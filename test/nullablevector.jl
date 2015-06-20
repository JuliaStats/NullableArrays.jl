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

    #----- test Base.pop! -----#

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

    Z = NullableArray([1:10...])
    @test isequal(shift!(Z), Nullable(1))
    @test isequal(Z, NullableArray([2:10...]))

    #----- test Base.splice! -----#


    #----- test Base.deleteat! -----#


    #----- test Base.append! -----#


    #----- test Base.sizehint! -----#


    #----- test padnull! -----#



end
