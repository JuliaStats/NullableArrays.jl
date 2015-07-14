module TestStatistics
    using NullableArrays
    using StatsBase
    using Base.Test

    srand(1)

    for N in (10, 100)
        A = rand(N)
        M = rand(Bool, N)
        mu_A = mean(A)
        nmu_A = Nullable(mu_A)
        i = rand(1:N)
        M[i] = true
        j = rand(1:N)
        while j == i
            j = rand(1:N)
        end
        M[j] = false
        X = NullableArray(A)
        Y = NullableArray(A, M)
        B = A[find(x->!x, M)]
        mu_B = mean(B)
        nmu_B = Nullable(mu_B)

        C = rand(N)
        V = WeightVec(C)
        R = rand(Bool, N)
        R[rand(1:N)] = true
        R[j] = false
        # W = WeightVec(NullableArray(C, R))

        J = find(i -> (!M[i] & !R[i]), [1:N...])

        # Test mean methods
        v = mean(X)
        @test_approx_eq v.value mean(A)
        @test !v.isnull
        v = mean(Y)
        @test isequal(v, Nullable{Float64}())
        v = mean(Y, skipnull=true)
        @test_approx_eq v.value mean(B)
        @test !v.isnull
        v = mean(X, V)
        @test_approx_eq v.value mean(A, V)
        @test !v.isnull
        # Following tests need to wait until WeightVec constructor is implemented
        # for NullableArray argument
        # @test isequal(mean(X, W), Nullable{Float64}())
        # @test isequal(mean(X, W, skipnull=true), Nullable(mean(A[J], WeightVec(C[J]))))

        # Test Base.varzm
        D1 = rand(round(Int, N / 2))
        D2 = -1 .* D1
        D = [D1; D2]
        while mean(D) != 0
            D1 = rand(round(Int, N / 2))
            D2 = -1 .* D1
            D = [D1; D2]
        end
        Q = NullableArray(D)
        S = rand(Bool, round(Int, N / 2))
        U = NullableArray(D, [S; S])
        E = [D[find(x->!x, S)]; D[find(x->!x, S)]]

        v = Base.varzm(Q)
        @test_approx_eq v.value Base.varzm(D)
        @test !v.isnull
        v = Base.varzm(Q, corrected=false)
        @test_approx_eq v.value Base.varzm(D, corrected=false)
        @test !v.isnull
        v = Base.varzm(U)
        @test isequal(v, Nullable{Float64}())
        v = Base.varzm(U, corrected=false)
        @test isequal(v, Nullable{Float64}())
        v = Base.varzm(U, skipnull=true)
        @test_approx_eq v.value Base.varzm(E)
        @test !v.isnull
        v = Base.varzm(U, corrected=false, skipnull=true)
        @test_approx_eq v.value Base.varzm(E, corrected=false)

        @test_throws NullException varm(Y, Nullable{Float64}())

        for corr in (true, false), skip in (true, false)
            # Test varm, stdm
            for method in (varm, stdm)
                for mu in (mu_A, nmu_A)
                    v = method(X, mu, corrected=corr, skipnull=skip)
                    @test_approx_eq v.value method(A, mu_A, corrected=corr)
                    @test !v.isnull
                end

                for mu in (mu_B, nmu_B)
                    v = method(Y, mu, corrected=corr, skipnull=skip)
                    if skip == false
                        @test isequal(v, Nullable{Float64}())
                    else
                        @test_approx_eq v.value method(B, mu_B, corrected=corr)
                        @test !v.isnull
                    end
                end
            end

            # Test var, std
            for method in (var, std)
                for mu in (nothing, mu_A, nmu_A)
                    v = method(X, mean=mu, corrected=corr, skipnull=skip)
                    @test_approx_eq v.value method(A, mean=mu_A, corrected=corr)
                    @test !v.isnull
                end

                for mu in (nothing, mu_B, nmu_B)
                    v = method(Y, mean=mu, corrected=corr, skipnull=skip)
                    if skip == false
                        @test isequal(v, Nullable{Float64}())
                    else
                        @test_approx_eq v.value method(B, mean=mu_B, corrected=corr)
                        @test !v.isnull
                    end
                end
            end
        end
    end
end
