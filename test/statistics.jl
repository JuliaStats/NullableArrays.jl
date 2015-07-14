module TestStatistics
    using NullableArrays
    using StatsBase
    using Base.Test

    srand(1)
    A = rand(10)
    M = rand(Bool, 10)
    mu_A = mean(A)
    nmu_A = Nullable(mu_A)
    i = rand(1:10)
    M[rand(1:5)] = true
    j = rand(1:10)
    while j == i
        j = rand(1:10)
    end
    M[j] = false
    X = NullableArray(A)
    Y = NullableArray(A, M)
    B = A[find(x->!x, M)]
    mu_B = mean(B)
    nmu_B = Nullable(mu_B)

    C = rand(10)
    V = WeightVec(C)
    R = rand(Bool, 10)
    R[rand(1:10)] = true
    R[j] = false
    # W = WeightVec(NullableArray(C, R))

    J = find(i -> (!M[i] & !R[i]), [1:10...])

    # Test mean methods
    @test isequal(mean(X), Nullable(mean(A)))
    @test isequal(mean(Y), Nullable{Float64}())
    @test isequal(mean(Y, skipnull=true), Nullable(mean(B)))
    @test isequal(mean(X, V), Nullable(mean(A, V)))
    # Following tests need to wait until WeightVec constructor is implemented
    # for NullableArray argument
    # @test isequal(mean(X, W), Nullable{Float64}())
    # @test isequal(mean(X, W, skipnull=true), Nullable(mean(A[J], WeightVec(C[J]))))

    # Test varm methods
    @test isequal(varm(X, mu_A), Nullable(varm(A, mu_A)))
    @test isequal(varm(X, mu_A, corrected=false),
                  Nullable(varm(A, mu_A, corrected=false)))
    @test isequal(varm(Y, mu_B), Nullable{Float64}())
    @test isequal(varm(Y, mu_B, corrected=false), Nullable{Float64}())
    @test isequal(varm(Y, mu_B, skipnull=true),
                  Nullable(varm(B, mu_B)))
    @test isequal(varm(Y, mu_B, corrected=false, skipnull=true),
                  Nullable(varm(B, mu_B, corrected=false)))

    @test isequal(varm(X, nmu_A), Nullable(varm(A, mu_A)))
    @test isequal(varm(X, nmu_A, corrected=false),
                  Nullable(varm(A, mu_A, corrected=false)))
    @test isequal(varm(Y, nmu_B), Nullable{Float64}())
    @test isequal(varm(Y, nmu_B, corrected=false), Nullable{Float64}())
    @test isequal(varm(Y, nmu_B, skipnull=true),
                  Nullable(varm(B, mu_B)))
    @test isequal(varm(Y, nmu_B, corrected=false, skipnull=true),
                  Nullable(varm(B, mu_B, corrected=false)))

    @test_throws NullException varm(Y, Nullable{Float64}())

    # Test Base.varzm
    D1 = rand(5)
    D2 = -1 .* D1
    D = [D1; D2]
    @test mean(D) == 0
    Q = NullableArray(D)
    S = rand(Bool, 5)
    U = NullableArray(D, [S; S])
    E = [D[find(x->!x, S)]; D[find(x->!x, S)]]

    @test isequal(Base.varzm(Q), Nullable(Base.varzm(D)))
    @test isequal(Base.varzm(Q, corrected=false),
                  Nullable(Base.varzm(D, corrected=false)))
    @test isequal(Base.varzm(U), Nullable{Float64}())
    @test isequal(Base.varzm(U, corrected=false), Nullable{Float64}())
    @test isequal(Base.varzm(U, skipnull=true),
                  Nullable(Base.varzm(E)))
    @test isequal(Base.varzm(U, corrected=false, skipnull=true),
                  Nullable(Base.varzm(E, corrected=false)))

    # Test var
    @test isequal(var(X), Nullable(var(A)))
    @test isequal(var(X, corrected=false), Nullable(var(A, corrected=false)))
    @test isequal(var(X, mean=mu_A), Nullable(var(A, mean=mu_A)))
    @test isequal(var(X, mean=nmu_A), Nullable(var(A, mean=mu_A)))
    @test isequal(var(X, mean=mu_A, corrected=false),
                  Nullable(var(A, mean=mu_A, corrected=false)))
    @test isequal(var(X, mean=nmu_A, corrected=false),
                  Nullable(var(A, mean=mu_A, corrected=false)))

    @test isequal(var(Y), Nullable{Float64}())
    @test isequal(var(Y, corrected=false), Nullable{Float64}())
    @test isequal(var(Y, mean=mu_B), Nullable{Float64}())
    @test isequal(var(Y, mean=nmu_B), Nullable{Float64}())
    @test isequal(var(Y, mean=mu_B, corrected=false),
                  Nullable{Float64}())
    @test isequal(var(Y, mean=nmu_B, corrected=false),
                  Nullable{Float64}())

    @test isequal(var(Y, skipnull=true),
                  Nullable(var(B)))
    @test isequal(var(Y, corrected=false, skipnull=true),
                  Nullable(var(B, corrected=false)))
    @test isequal(var(Y, mean=mu_B, skipnull=true),
                  Nullable(var(B, mean=mu_B)))
    @test isequal(var(Y, mean=nmu_B, skipnull=true),
                  Nullable(var(B, mean=mu_B)))
    @test isequal(var(Y, mean=mu_B, corrected=false, skipnull=true),
                  Nullable(var(B, mean=mu_B, corrected=false)))
    @test isequal(var(Y, mean=nmu_B, corrected=false, skipnull=true),
                  Nullable(var(B, mean=mu_B, corrected=false)))

    # Test stdm
    @test isequal(stdm(X, mu_A), Nullable(stdm(A, mu_A)))
    @test isequal(stdm(X, mu_A, corrected=false),
                  Nullable(stdm(A, mu_A, corrected=false)))
    @test isequal(stdm(Y, mu_B), Nullable{Float64}())
    @test isequal(stdm(Y, mu_B, corrected=false), Nullable{Float64}())
    @test isequal(stdm(Y, mu_B, skipnull=true),
                  Nullable(stdm(B, mu_B)))
    @test isequal(stdm(Y, mu_B, corrected=false, skipnull=true),
                  Nullable(stdm(B, mu_B, corrected=false)))

    @test isequal(stdm(X, nmu_A), Nullable(stdm(A, mu_A)))
    @test isequal(stdm(X, nmu_A, corrected=false),
                  Nullable(stdm(A, mu_A, corrected=false)))
    @test isequal(stdm(Y, nmu_B), Nullable{Float64}())
    @test isequal(stdm(Y, nmu_B, corrected=false), Nullable{Float64}())
    @test isequal(stdm(Y, nmu_B, skipnull=true),
                  Nullable(stdm(B, mu_B)))
    @test isequal(stdm(Y, nmu_B, corrected=false, skipnull=true),
                  Nullable(stdm(B, mu_B, corrected=false)))

    # Test std
    @test isequal(std(X), Nullable(std(A)))
    @test isequal(std(X, corrected=false), Nullable(std(A, corrected=false)))
    @test isequal(std(X, mean=mu_A), Nullable(std(A, mean=mu_A)))
    @test isequal(std(X, mean=nmu_A), Nullable(std(A, mean=mu_A)))
    @test isequal(std(X, mean=mu_A, corrected=false),
                  Nullable(std(A, mean=mu_A, corrected=false)))
    @test isequal(std(X, mean=nmu_A, corrected=false),
                  Nullable(std(A, mean=mu_A, corrected=false)))

    @test isequal(std(Y), Nullable{Float64}())
    @test isequal(std(Y, corrected=false), Nullable{Float64}())
    @test isequal(std(Y, mean=mu_B), Nullable{Float64}())
    @test isequal(std(Y, mean=nmu_B), Nullable{Float64}())
    @test isequal(std(Y, mean=mu_B, corrected=false),
                  Nullable{Float64}())
    @test isequal(std(Y, mean=nmu_B, corrected=false),
                  Nullable{Float64}())

    @test isequal(std(Y, skipnull=true),
                  Nullable(std(B)))
    @test isequal(std(Y, corrected=false, skipnull=true),
                  Nullable(std(B, corrected=false)))
    @test isequal(std(Y, mean=mu_B, skipnull=true),
                  Nullable(std(B, mean=mu_B)))
    @test isequal(std(Y, mean=nmu_B, skipnull=true),
                  Nullable(std(B, mean=mu_B)))
    @test isequal(std(Y, mean=mu_B, corrected=false, skipnull=true),
                  Nullable(std(B, mean=mu_B, corrected=false)))
    @test isequal(std(Y, mean=nmu_B, corrected=false, skipnull=true),
                  Nullable(std(B, mean=mu_B, corrected=false)))
end
