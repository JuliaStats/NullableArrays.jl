using NullableArrays

srand(1)
N = 5_000_000
A = rand(N)
B = rand(Bool, N)
C = Array(Float64, N)


X = NullableArray(A)
Y = NullableArray(A, B)
Z = NullableArray(Float64, N)

f(x::Float64) = 5 * x

function profile_map()

    println("Method: map!(f, dest, src) (0 missing entries, lift=true)")
    print("  for Array{Float64}:          ")
    map!(f, C, A);
    @time map!(f, C, A);
    print("  for NullableArray{Float64}:  ")
    map!(f, Z, X; lift=true);
    @time map!(f, Z, X; lift=true);
    println()

    println("Method: map!(f, dest, src) (~half missing entries, lift=true)")
    print("  for NullableArray{Float64}:  ")
    map!(f, Z, Y; lift=true);
    @time map!(f, Z, Y; lift=true);
    println()

    println("Method: map(f, src) (0 missing entries, lift=true)")
    print("  for Array{Float64}:          ")
    map(f, A);
    @time map(f, A);
    print("  for NullableArray{Float64}:  ")
    map(f, X; lift=true);
    @time map(f, X; lift=true);
    println()

    println("Method: map(f, src) (~half missing entries, lift=true)")
    print("  for NullableArray{Float64}:  ")
    map(f, Y; lift=true);
    @time map(f, Y; lift=true);
    println()
end
