module TestMap
    using Base.Test
    using NullableArrays

    A = rand(10)
    B = [1:10...]
    X = NullableArray([1:10...])
    Y = NullableArray(A)
    Z = NullableArray(A, vcat(fill(true, 5), fill(false, 5)))
    f{T}(x::Nullable{T}) = return Nullable(5*x.value, x.isnull)
    f{T}(x::Nullable{T}, y::Number) = Nullable(x.value*y, x.isnull)
    f{T}(x::Number, y::Nullable{T}) = f(y, x)
    f(x::Nullable, y::Nullable) = Nullable(x.value*y.value,
                                           x.isnull | y.isnull)
    function f(x::Nullable, y::Nullable, z::Nullable)
        Nullable(x.value*y.value*z.value, x.isnull | y.isnull | z.isnull)
    end

    @test isequal(map(f, X), NullableArray([ 5*i for i in 1:10 ]))
    @test isequal(map(f, X, A),
                  NullableArray([ X.values[i]*A[i] for i in 1:10 ])
    )
    @test isequal(map(f, X, Y),
                  NullableArray([ X.values[i]*A[i] for i in 1:10])
    )
    @test isequal(map(f, X, Z),
                  NullableArray([ X.values[i]*A[i] for i in 1:10],
                                vcat(fill(true, 5), fill(false, 5))
                  )
    )
    @test isequal(map(f, X, Y, Z),
                  NullableArray([ X.values[i]*A[i]*A[i] for i in 1:10 ],
                                vcat(fill(true, 5), fill(false, 5))
                  )
    )

    @test isequal(map!(f, similar(X), X), NullableArray([ 5*i for i in 1:10 ]))
    @test isequal(map!(f, NullableArray(Float64, 10), X, Y, Z),
                  NullableArray([ X.values[i]*A[i]*A[i] for i in 1:10 ],
                                vcat(fill(true, 5), fill(false, 5))
                  )
    )

end
