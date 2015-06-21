module TestMatrix
    using NullableArrays
    using Base.Test

    #----- test Base.diag -----#
    A = reshape([1:25...], 5, 5)
    m = fill(false, 5, 5)
    m[1] = true
    m[25] = true
    X = NullableArray(A)
    Y = NullableArray(A, m)

    @test isequal(diag(X), NullableArray([1, 7, 13, 19, 25]))
    @test isequal(diag(Y), NullableArray([1, 7, 13, 19, 25],
                                         [true, false, false, false, true]))

end
