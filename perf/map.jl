using NullableArrays

srand(1)
A = rand(5_000_000)
B = rand(Bool, 5_000_000)

X = NullableArray(Float64, 5_000_000)
Y = NullableArray(A)
Z = NullableArray(A, B)

f{T}(x::Nullable{T}) = return Nullable(5*x.value, x.isnull)

function test_map()
    map!(f, X, Y)
    map!(f, X, Z)
    # map!(f, X, Y)
    @time(map!(f, X, Y))
    @time(map!(f, X, Z))
end
