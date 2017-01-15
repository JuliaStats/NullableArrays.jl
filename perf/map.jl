using NullableArrays

srand(1)
N = 5_000_000
A = rand(N)
B = rand(Bool, N)
C = Array{Float64}(N)


X = NullableArray(A)
Y = NullableArray(A, B)
Z = NullableArray(Float64, N)

f(x::Float64) = 5 * x

function profile_map()

    println("Method: map!(f, dest, src) (0 missing entries)")
    print("  for Array{Float64}:          ")
    map!(f, C, A);
    @time map!(f, C, A);
    print("  for NullableArray{Float64}:  ")
    map!(f, Z, X);
    @time map!(f, Z, X);
    println()

    println("Method: map!(f, dest, src) (~half missing entries)")
    print("  for NullableArray{Float64}:  ")
    map!(f, Z, Y);
    @time map!(f, Z, Y);
    println()

    println("Method: map(f, src) (0 missing entries)")
    print("  for Array{Float64}:          ")
    map(f, A);
    @time map(f, A);
    print("  for NullableArray{Float64}:  ")
    map(f, X);
    @time map(f, X);
    println()

    println("Method: map(f, src) (~half missing entries)")
    print("  for NullableArray{Float64}:  ")
    map(f, Y);
    @time map(f, Y);
    println()
end
