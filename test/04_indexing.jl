module TestIndexing
    using Base.Test
    using NullableArrays

    x = NullableArray(Int, (5, 2))

    for i in eachindex(x)
        x[i] = i
    end

    for i in eachindex(x)
        y = x[i]
        @test isa(y, Nullable{Int})
        @test get(y) === i
    end

    for i in eachindex(x)
        x[i] = Nullable{Int}()
    end

    for i in eachindex(x)
        y = x[i]
        @test isa(y, Nullable{Int})
        @test isnull(y)
    end

    _values = rand(10, 10)
    _isnull = rand(Bool, 10, 10)
    X = NullableArray(_values, _isnull)

    # Scalar getindex
    for i = 1:100
        if _isnull[i]
            @test isnull(X[i])
        else
            @test isequal(X[i], Nullable(_values[i]))
        end
    end
    for i = 1:10, j = 1:10
        if _isnull[i, j]
            @test isnull(X[i, j])
        else
            @test isequal(X[i, j], Nullable(_values[i, j]))
        end
    end

    # getindex with AbstractVectors
    rg = 2:9
    v = X[rg]
    for i = 1:length(rg)
        if _isnull[rg[i]]
            @test isnull(v[i])
        else
            @test isequal(v[i], Nullable(_values[rg[i]]))
        end
    end

    v = X[rg, 9]
    for i = 1:length(rg)
        if _isnull[rg[i], 9]
            @test isnull(v[i])
        else
            @test isequal(v[i], Nullable(_values[rg[i], 9]))
        end
    end

    rg2 = 5:7
    v = X[rg, rg2]
    for j = 1:length(rg2), i = 1:length(rg)
        if _isnull[rg[i], rg2[j]]
            @test isnull(v[i, j])
        else
            @test isequal(v[i, j], Nullable(_values[rg[i], rg2[j]]))
        end
    end

    # getindex with AbstractVector{Bool}
    b = bitrand(10, 10)
    rg = find(b)
    v = X[b]
    for i = 1:length(rg)
        if _isnull[rg[i]]
            @test isnull(v[i])
        else
            @test isequal(v[i], Nullable(_values[rg[i]]))
        end
    end

    # getindex with valuesVectors with missingness throws
    @test_throws NullException X[NullableArray([1, 2, 3, nothing], Int, Void)]

    # setindex! with scalar indices
    _values = rand(10, 10)
    for i = 1:100
        X[i] = _values[i]
    end
    @test isequal(X, NullableArray(_values))

    _values = rand(10, 10)
    for i = 1:10, j = 1:10
        X[i, j] = _values[i, j]
    end
    @test isequal(X, NullableArray(_values))

# ----- test nullify -----#
    _isnull = bitrand(10, 10)
    for i = 1:100
        _isnull[i] && (nullify(X, i))
    end

    # setindex! with scalar and vector indices
    rg = 2:9
    _values[rg] = 1.0
    X[rg] = 1.0
    for i = 1:length(rg)
        @test isequal(X[rg[i]], Nullable(1.0))
    end

    # setindex! with NA and vector indices
    rg = 5:13
    _isnull[rg] = true
    nullify(X, rg)
    for i = 1:length(rg)
        @test isnull(X[rg[i]])
    end

    # setindex! with vector and vector indices
    rg = 12:67
    _values[rg] = rand(length(rg))
    X[rg] = _values[rg]
    for i = 1:length(rg)
        @test isequal(X[rg[i]], Nullable(_values[rg[i]]))
    end

end
