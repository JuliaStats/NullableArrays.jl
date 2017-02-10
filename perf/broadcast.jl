using DataArrays
using NullableArrays

srand(1)
M1 = rand(Bool, 5_000_000)
M2 = rand(Bool, 5_000_000, 2)
A1 = rand(5_000_000)
A2 = rand(Float64, 5_000_000, 2)
B1 = rand(Bool, 5_000_000)
B2 = rand(Bool, 5_000_000, 2)
C1 = rand(1:10, 5_000_000)
C2 = rand(Int, 5_000_000, 2)
L = Array{Float64}(5_000_000, 2)

U = NullableArray(Float64, 5_000_000, 2)
X1 = NullableArray(A1)
X2 = NullableArray(A2)
Y1 = NullableArray(A1, M1)
Y2 = NullableArray(A2, M2)
Z1 = NullableArray(B1)
Z2 = NullableArray(B2)
Q1 = NullableArray(C1)
Q2 = NullableArray(C2)
V1 = NullableArray(C1, M1)
V2 = NullableArray(C2, M2)

D = DataArray(Float64, 5_000_000, 2)
E1 = DataArray(A1)
E2 = DataArray(A2)
F1 = DataArray(A1, M1)
F2 = DataArray(A2, M2)
G1 = DataArray(B1)
G2 = DataArray(B2)
H1 = DataArray(C1)
H2 = DataArray(C2)
I1 = DataArray(C1, M1)
I2 = DataArray(C2, M2)

f(x, y) = x * y

function profile_broadcast(f, L, U, D, A1, A2, X1, X2, E1, E2, Y1, Y2, F1, F2)
    println("f(x, y) := x * y")
    println("Method: broadcast!(f, dest, A1, A2) (no empty entries):")
    broadcast!(f, L, A1, A2)
    print("  For Array{Float64}:          ")
    @time(broadcast!(f, L, A1, A2))

    broadcast!(f, U, X1, X2)
    print("  For NullableArray{Float64}:  ")
    @time(broadcast!(f, U, X1, X2))

    broadcast!(f, D, E1, E2)
    print("  For DataArray{Float64}:      ")
    @time(broadcast!(f, D, E1, E2))

    println()
    println("Method: broadcast!(f, dest, A1, A2) (~half empty entries):")
    broadcast!(f, U, Y1, Y2)
    print("  For NullableArray{Float64}:  ")
    @time(broadcast!(f, U, Y1, Y2))

    print("  For DataArray{Float64}:      ")
    broadcast!(f, D, F1, F2)
    @time(broadcast!(f, D, F1, F2))
    nothing
end

function profile_ops_nonulls(A1, A2, X1, X2, E1, E2)
    for op in (
        :(.+),
        :(.-),
        :(.*),
        :(./),
        :(.%),
        :(.^),
    )
        _op = Symbol("$op")
        println("Method: $_op (no empty entries)")
        @eval begin
            $_op(A1, A2)
            $_op(X1, X2)
            $_op(E1, E2)
            print("  For Array{Float64}:          ")
            @time($_op(A1, A2))
            print("  For NullableArray{Float64}:  ")
            @time($_op(X1, X2))
            print("  For DataArray{Float64}:      ")
            @time($_op(E1, E2))
        end
    end

    for op in (
        :(.==),
        :(.!=),
        :(.<),
        :(.>),
        :(.<=),
        :(.>=),
    )
        _op = Symbol("$op")
        println("Method: $_op (no empty entries)")
        @eval begin
            $_op(A1, A2)
            $_op(X1, X2)
            $_op(E1, E2)
            print("  For Array{Float64}:          ")
            @time($_op(A1, A2))
            print("  For NullableArray{Float64}:  ")
            @time($_op(X1, X2))
            print("  For DataArray{Float64}:      ")
            @time($_op(E1, E2))
        end
    end
    nothing
end

function profile_broadcasted_right(C1, C2, V1, V2, H1, H2, Q1, Q2)
    println("Method: .>> (no empty entries)")
    .>>(C2, C1)
    .>>(V2, V1)
    .>>(H2, H1)
    print("  For Array{Float64}:          ")
    @time(.>>(C2, C1))
    print("  For NullableArray{Float64}:  ")
    @time(.>>(V2, V1))
    print("  For DataArray{Float64}:      ")
    @time(.>>(H2, H1))

    println("Method: .>> (~half empty entries)")
    .>>(C2, C1)
    .>>(Q2, Q1)
    # .>>(I2, I1)
    print("  For Array{Float64}:          ")
    @time(.>>(C2, C1))
    print("  For NullableArray{Float64}:  ")
    @time(.>>(Q2, Q1))
    # print("For DataArray{Float64}:      ")
    # @time(.>>(I2, I1))
    nothing
end

function profile_ops_halfnulls(A1, A2, Y1, Y2, F1, F2)
    for op in (
        :(.+),
        :(.-),
        :(.*),
        :(./),
        :(.%),
        :(.^),
    )
        _op = Symbol("$op")
        println("Method: $_op (~half empty entries)")
        @eval begin
            $_op(A1, A2)
            $_op(Y1, Y2)
            $_op(F1, F2)
            print("  For Array{Float64}:          ")
            @time($_op(A1, A2))
            print("  For NullableArray{Float64}:  ")
            @time($_op(Y1, Y2))
            print("  For DataArray{Float64}:      ")
            @time($_op(F1, F2))
        end
    end

    for op in (
        :(.==),
        :(.!=),
        :(.<),
        :(.>),
        :(.<=),
        :(.>=),
    )
        _op = Symbol("$op")
        println("Method: $_op (~half empty entries)")
        @eval begin
            $_op(A1, A2)
            $_op(Y1, Y2)
            $_op(F1, F2)
            print("  For Array{Float64}:          ")
            @time($_op(A1, A2))
            print("  For NullableArray{Float64}:  ")
            @time($_op(Y1, Y2))
            print("  For DataArray{Float64}:      ")
            @time($_op(F1, F2))
        end
    end
    nothing
end

function profile_broadcast_all()
    profile_broadcast(f, L, U, D, A1, A2, X1, X2, E1, E2, Y1, Y2, F1, F2)
    profile_ops_nonulls(A1, A2, X1, X2, E1, E2)
    profile_ops_halfnulls(A1, A2, Y1, Y2, F1, F2)
    profile_broadcasted_right(C1, C2, V1, V2, H1, H2, Q1, Q2)
end
