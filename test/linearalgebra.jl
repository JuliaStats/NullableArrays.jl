module TestLinearAlgebra
    using NullableArrays
    using DataArrays
    using Base.Test

    B = rand(Bool, 10, 10)
    M = rand(Float64, 10, 10)

    X = NullableArray(M, B)
    D = DataArray(M, B)
    nullify!(X, 1)

    isequal(svd(X, impute=true), svd(D))
    @test isequal(svd(X, impute=true), svd(D))
    @test isequal(eig(X, impute=true), eig(D))
    @test_throws ArgumentError svd(X)
    @test_throws ArgumentError svd(X, minimum(size(X)))
    @test_throws ArgumentError eig(X)
end
