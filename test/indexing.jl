module TestIndexing
    using Base.Test
    using NullableArrays
    import NullableArrays: unsafe_getindex_notnull,
                           unsafe_getvalue_notnull

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

    # Base.getindex{T, N}(X::NullableArray{T, N})
    @test isequal(getindex(X), X[1])

    # Base.getindex{T, N}(X::NullableArray{T, N}, I::Nullable{Int}...)
    @test_throws NullException getindex(X, Nullable{Int}(), Nullable{Int}())
    if _isnull[1]
        @test isnull(getindex(X, Nullable(1)))
    else
        @test isequal(getindex(X, Nullable(1)), Nullable(_values[1]))
    end

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

    # ensure that the NullableArray returned by getindex maintains its parent field
    str = "something"
    x = NullableArray([pointer(str), pointer(str, 5)], [false, false], Vector{UInt8}(str))
    @test x[1:2].parent === x.parent
    @test x[:].parent === x.parent

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

    # range indexing
    Z_values = reshape(collect(1:125), (5,5,5))
    Z = NullableArray(Z_values)

    if VERSION > v"0.5.0-dev+1195" # PR #13612 in JuliaLang
        @test isequal(Z[1, 1:4, 1], NullableArray([1, 6, 11, 16]))
    else
        @test isequal(Z[1, 1:4, 1], NullableArray([1 6 11 16]))
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

    # getindex with NullableVector with null entries throws error
    @test_throws NullException X[NullableArray([1, 2, 3, nothing], Int, Void)]

    # getindex with NullableVector and non-null entries
    @test isequal(X[NullableArray([1, 2, 3])], X[[1, 2, 3]])

    # indexing with Nullables

    n = rand(1:5)
    siz = [ rand(2:5) for i in n ]
    A = rand(siz...)
    M = rand(Bool, siz...)
    Z = NullableArray(A, M)
    i = rand(1:length(Z))
    @test isequal(Z[Nullable(i)], Z[i])
    I = [ rand(1:size(Z,i)) for i in 1:n ]
    NI = [ Nullable(i) for i in I ]
    @test isequal(Z[NI...], Z[I...])

    #----- test setindex! -----#

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

    _values = rand(10, 10)
    for i = 1:10, j = 1:10
        X[i, j] = Nullable(_values[i, j])
    end
    @test isequal(X, NullableArray(_values))


    # ----- test nullify! -----#
    _isnull = bitrand(10, 10)
    for i = 1:100
        _isnull[i] && (nullify!(X, i))
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
    nullify!(X, rg)
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

    #----- test UNSAFE INDEXING -----#

    X = NullableArray([1, 2, 3, 4, 5], [true, false, false, false, false])

    @test isequal(unsafe_getindex_notnull(X, 1), Nullable(1))
    @test isequal(unsafe_getindex_notnull(X, 2), Nullable(2))
    @test isequal(unsafe_getvalue_notnull(X, 1), 1)
    @test isequal(unsafe_getvalue_notnull(X, 2), 2)

    #----- test Base.checkbounds -----#

    X = NullableArray([1:10...])
    b = vcat(false, fill(true, 9))

    if VERSION >= v"0.5.0-dev+4697"
        # Base.checkindex(::Type{Bool}, inds::UnitRange, i::Nullable)
        @test_throws NullException checkindex(Bool, 1:1, Nullable{Int}())
        @test checkindex(Bool, 1:10, Nullable(1)) == true
        @test isequal(X[Nullable(1)], Nullable(1))

        # Base.checkindex{N}(::Type{Bool}, inds::UnitRange, I::NullableArray{Bool, N})
        @test checkindex(Bool, 1:5, NullableArray([true, false, true, false, true]))
        @test isequal(X[b], NullableArray([2:10...]))

        # Base.checkindex{T<:Real}(::Type{Bool}, inds::UnitRange, I::NullableArray{T})
        @test checkindex(Bool, 1:10, NullableArray([1:10...]))
        @test checkindex(Bool, 1:10, NullableArray([10, 11])) == false
        @test_throws BoundsError checkbounds(X, NullableArray([10, 11]))
    else
        # Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, x::Nullable{T})
        @test_throws NullException checkbounds(Bool, 1, Nullable(1, true))
        @test checkbounds(Bool, 10, Nullable(1)) == true
        @test isequal(X[Nullable(1)], Nullable(1))

        # Base.checkbounds(::Type{Bool}, sz::Int, X::NullableVector{Bool})
        @test checkbounds(Bool, 5, NullableArray([true, false, true, false, true]))
        @test isequal(X[b], NullableArray([2:10...]))

        # Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, I::NullableArray{T})
        @test checkbounds(Bool, 10, NullableArray([1:10...]))
        @test checkbounds(Bool, 10, NullableArray([10, 11])) == false
        @test_throws BoundsError checkbounds(X, NullableArray([10, 11]))
    end

    #---- test Base.to_index -----#

    # Base.to_index(X::NullableArray)
    @test Base.to_index(X) == [1:10...]
    push!(X, Nullable{Int}())
    @test_throws NullException Base.to_index(X)

end
