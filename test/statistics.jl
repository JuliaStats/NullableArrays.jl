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
        J = find(x -> !x, M)
        B = A[J]
        mu_B = mean(B)
        nmu_B = Nullable(mu_B)

        C = rand(N)
        V = WeightVec(C)
        R = rand(Bool, N)
        R[rand(1:N)] = true
        R[j] = false
        # W = WeightVec(NullableArray(C, R))

        K = find(x -> !x, R)
        L = find(i -> (!M[i] & !R[i]), [1:N...])

        # For testing Base.varzm
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

        @test_throws NullException varm(Y, Nullable{Float64}())

        # Test mean
        for skip in (true, false)
            v = mean(X, skipnull=skip)
            @test_approx_eq v.value mean(A)
            @test !v.isnull

            v = mean(Y, skipnull=skip)
            if skip == false
                @test isequal(v, Nullable{Float64}())
            else
                @test_approx_eq v.value mean(B)
                @test !v.isnull
            end

            v = mean(X, V, skipnull=skip)
            @test_approx_eq v.value mean(A, V)
            @test !v.isnull

            v = mean(Y, V, skipnull=skip)
            if skip == false
                @test isequal(v, Nullable{Float64}())
            else
                @test_approx_eq v.value mean(B, WeightVec(C[J]))
                @test !v.isnull
            end

            # Following tests need to wait until WeightVec constructor is
            # implemented for NullableArray argument
            #
            # v = mean(X, W, skipnull=skip)
            # if skip == false
            #     @test isequal(v, Nullable{Float64}())
            # else
            #     @test_approx_eq v.value mean(A[K], WeightVec(C[K]))
            #     @test !v.isnull
            # end
            # v = mean(Y, W, skipnull=skip)
            # if skip == false
            #     @test isequal(v, Nullable{Float64}())
            # else
            #     @test_approx_eq v.value mean(A[L], WeightVec(C[L]))
            #     @test !v.isnull
            # end
        end

        for corr in (true, false), skip in (true, false)
            # Test Base.varzm
            v = Base.varzm(Q, corrected=corr, skipnull=skip)
            @test_approx_eq v.value Base.varzm(D, corrected=corr)
            @test !v.isnull

            v = Base.varzm(U, corrected=corr, skipnull=skip)
            if skip == false
                @test isequal(v, Nullable{Float64}())
            else
                @test_approx_eq v.value Base.varzm(E, corrected=corr)
                @test !v.isnull
            end

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
