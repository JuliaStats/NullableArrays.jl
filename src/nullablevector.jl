"""
    push!{T, V}(X::NullableVector{T}, v::V)

Insert `v` at the end of `X`, which registers `v` as a present value.
"""
function Base.push!{T, V}(X::NullableVector{T}, v::V)
    push!(X.values, v)
    push!(X.isnull, false)
    return X
end

"""
    push!{T, V}(X::NullableVector{T}, v::Nullable{V})

Insert a value at the end of `X` from a `Nullable` value `v`. If `v` is null
then this method adds a null entry at the end of `X`. Returns `X`.
"""
function Base.push!{T, V}(X::NullableVector{T}, v::Nullable{V})
    if isnull(v)
        resize!(X.values, length(X.values) + 1)
        push!(X.isnull, true)
    else
        push!(X.values, v.value)
        push!(X.isnull, false)
    end
    return X
end

"""
    pop!{T}(X::NullableVector{T})

Remove the last entry from `X` and return it. If the value in that entry is
missing, then this method returns `Nullable{T}()`.
"""
function Base.pop!{T}(X::NullableVector{T}) # -> T
    val, isnull = pop!(X.values), pop!(X.isnull)
    isnull ? Nullable{T}() : Nullable(val)
end

"""
    unshift!(X::NullableVector, v::Nullable)

Insert a value at the beginning of `X` from a `Nullable` value `v`. If `v` is
null then this method inserts a null entry at the beginning of `X`. Returns `X`.
"""
function Base.unshift!(X::NullableVector, v::Nullable) # -> NullableVector{T}
    if isnull(v)
        ccall(:jl_array_grow_beg, Void, (Any, UInt), X.values, 1)
        unshift!(X.isnull, true)
    else
        unshift!(X.values, v.value)
        unshift!(X.isnull, false)
    end
    return X
end

"""
    unshift!(X::NullableVector, v)

Insert a value `v` at the beginning of `X` and return `X`.
"""
function Base.unshift!(X::NullableVector, v) # -> NullableVector{T}
    unshift!(X.values, v)
    unshift!(X.isnull, false)
    return X
end

"""
    shift!{T}(X::NullableVector{T})

Remove the first entry from `X` and return it as a `Nullable` object.
"""
function Base.shift!{T}(X::NullableVector{T}) # -> Nullable{T}
    val, isnull = shift!(X.values), shift!(X.isnull)
    if isnull
        return Nullable{T}()
    else
        return Nullable{T}(val)
    end
end

const _default_splice = []

"""
    splice!(X::NullableVector, i::Integer, [ins])

Remove the item at index `i` and return the removed item. Subsequent items
are shifted down to fill the resulting gap. If specified, replacement values from
an ordered collection will be spliced in place of the removed item.
"""
function Base.splice!(X::NullableVector, i::Integer, ins=_default_splice)
    v = X[i]
    m = length(ins)
    if m == 0
        deleteat!(X.values, i)
        deleteat!(X.isnull, i)
    elseif m == 1
        X[i] = ins
    else
        Base._growat!(X.values, i, m-1)
        Base._growat!(X.isnull, i, m-1)
        for k = 1:endof(ins)
            X[i + k - 1] = ins[k]
        end
    end
    return v
end

"""
    splice!{T<:Integer}(X::NullableVector, rng::UnitRange{T}, [ins])

Remove items in the specified index range, and return a collection containing
the removed items. Subsequent items are shifted down to fill the resulting gap.
If specified, replacement values from an ordered collection will be spliced in
place of the removed items.

To insert `ins` before an index `n` without removing any items, use
`splice!(X, n:n-1, ins)`.
"""
function Base.splice!{T<:Integer}(X::NullableVector,
                                  rng::UnitRange{T},
                                  ins=_default_splice) # ->
    vs = X[rng]
    m = length(ins)
    if m == 0
        deleteat!(X.values, rng)
        deleteat!(X.isnull, rng)
        return vs
    end

    n = length(X)
    d = length(rng)
    f = first(rng)
    l = last(rng)

    if VERSION >= v"0.5.0-dev+5022"
        if m < d # insert is shorter than range
            delta = d - m
            i = (f - 1 < n - l) ? f : (l - delta + 1)
            Base._deleteat!(X.values, i, delta)
            Base._deleteat!(X.isnull, i, delta)
        elseif m > d # insert is longer than range
            delta = m - d
            i = (f - 1 < n - l) ? f : (l + 1)
            Base._growat!(X.values, i, delta)
            Base._growat!(X.isnull, i, delta)
        end
    else
        if m < d # insert is shorter than range
            delta = d - m
            if f - 1 < n - l
                Base._deleteat_beg!(X.values, f, delta)
                Base._deleteat_beg!(X.isnull, f, delta)
            else
                Base._deleteat_end!(X.values, l - delta + 1, delta)
                Base._deleteat_end!(X.isnull, l - delta + 1, delta)
            end
        elseif m > d # insert is longer than range
            delta = m - d
            if f -  1 < n - l
                Base._growat_beg!(X.values, f, delta)
                Base._growat_beg!(X.isnull, f, delta)
            else
                Base._growat_end!(X.values, l + 1, delta)
                Base._growat_end!(X.isnull, l + 1, delta)
            end
        end
    end

    for k = 1:endof(ins)
        X[f + k - 1] = ins[k]
    end
    return vs
end

"""
    deleteat!(X::NullableVector, inds)

Delete the entry at `inds` from `X` and then return `X`. Note that `inds` may
be either a single scalar index or a collection of sorted, pairwise unique
indices. Subsequent items after deleted entries are shifted down to fill the
resulting gaps.
"""
function Base.deleteat!(X::NullableVector, inds)
    deleteat!(X.values, inds)
    deleteat!(X.isnull, inds)
    return X
end

"""
    append!(X::NullableVector, items::AbstractVector)

Add the elements of `items` to the end of `X`.

Note that `append!(X, [1, 2, 3])` is equivalent to `push!(X, 1, 2, 3)`,
where the items to be added to `X` are passed individually to `push!` and as a
collection to `append!`.
"""
function Base.append!(X::NullableVector, items::AbstractVector)
    old_length = length(X)
    nitems = length(items)
    resize!(X, old_length + nitems)
    copy!(X, length(X)-nitems+1, items, 1, nitems)
    return X
end

"""
    prepend!(X::NullableVector, items::AbstractVector)

Add the elements of `items` to the beginning of `X`.

Note that `prepend!(X, [1, 2, 3])` is equivalent to `unshift!(X, 1, 2, 3)`,
where the items to be added to `X` are passed individually to `unshift!` and as a
collection to `prepend!`.
"""
function Base.prepend!(X::NullableVector, items::AbstractVector)
    old_length = length(X)
    nitems = length(items)
    ccall(:jl_array_grow_beg, Void, (Any, UInt), X.values, nitems)
    ccall(:jl_array_grow_beg, Void, (Any, UInt), X.isnull, nitems)
    if X === items
        copy!(X, 1, items, nitems+1, nitems)
    else
        copy!(X, 1, items, 1, nitems)
    end
    return X
end

"""
    sizehint!(X::NullableVector, newsz::Integer)

Suggest that collection `X` reserve capacity for at least `newsz` elements.
This can improve performance.
"""
function Base.sizehint!(X::NullableVector, newsz::Integer)
    sizehint!(X.values, newsz)
    sizehint!(X.isnull, newsz)
end

"""
    padnull!(X::NullableVector, front::Integer, back::Integer)

Insert `front` null entries at the beginning of `X` and add `back` null entries
at the end of `X`. Returns `X`.
"""
function padnull!{T}(X::NullableVector{T}, front::Integer, back::Integer)
    prepend!(X, fill(Nullable{T}(), front))
    append!(X, fill(Nullable{T}(), back))
    return X
end

"""
    padnull(X::NullableVector, front::Integer, back::Integer)

return a copy of `X` with `front` null entries inserted at the beginning of
the copy and `back` null entries inserted at the end.
"""
function padnull(X::NullableVector, front::Integer, back::Integer)
    return padnull!(copy(X), front, back)
end

"""
    reverse!(X::NullableVector, [s], [n])

Modify `X` by reversing the first `n` elements starting at index `s`
(inclusive). If unspecified, `s` and `n` will default to `1` and `length(X)`,
respectively.
"""
function Base.reverse!(X::NullableVector, s=1, n=length(X))
    if isbits(eltype(X)) || !anynull(X)
        reverse!(X.values, s, n)
        reverse!(X.isnull, s, n)
    else
        r = n
        for i in s:div(s+n-1, 2)
            if !X.isnull[i]
                if !X.isnull[r]
                    X.values[i], X.values[r] = X.values[r], X.values[i]
                else
                    X.values[r] = X.values[i]
                end
            elseif !X.isnull[r]
                X.values[i] = X.values[r]
            end
            r -= 1
        end
        reverse!(X.isnull, s, n)
    end
    return X
end

"""
    reverse(X::NullableVector, [s], [n])

Return a copy of `X` with the first `n` elements starting at index `s`
(inclusive) reversed. If unspecified, `s` and `n` will default to `1` and
`length(X)`, respectively.
"""
function Base.reverse(X::NullableVector, s=1, n=length(X))
    return reverse!(copy(X), s, n)
end

"""
    empty!(X::NullableVector) -> NullableVector

Remove all elements from a `NullableVector`. Returns `NullableVector{T}()`,
where `T` is the `eltype` of `X`.
"""
function Base.empty!(X::NullableVector)
    empty!(X.values)
    empty!(X.isnull)
    return X
end

function Base.promote_rule{T1,T2}(::Type{T1}, ::Type{Nullable{T2}})
    promote_rule(Nullable{T2}, T1)
end

function Base.typed_hcat{T}(::Type{T}, A::AbstractVecOrMat...)
    nargs = length(A)
    nrows = size(A[1], 1)
    ncols = 0
    dense = true
    for j = 1:nargs
        Aj = A[j]
        if size(Aj, 1) != nrows
            throw(ArgumentError("number of rows of each array must match (got $(map(x->size(x,1), A)))"))
        end
        dense &= isa(Aj,Array)
        nd = ndims(Aj)
        ncols += (nd==2 ? size(Aj,2) : 1)
    end
    i = findfirst(a -> isa(a, NullableArray), A)
    B = similar(full(A[i == 0 ? 1 : i]), T, nrows, ncols)
    pos = 1
    if dense
        for k=1:nargs
            Ak = A[k]
            n = length(Ak)
            copy!(B, pos, Ak, 1, n)
            pos += n
        end
    else
        for k=1:nargs
            Ak = A[k]
            p1 = pos+(isa(Ak,AbstractMatrix) ? size(Ak, 2) : 1)-1
            B[:, pos:p1] = Ak
            pos = p1+1
        end
    end
    return B
end

function Base.typed_vcat{T}(::Type{T}, V::AbstractVector...)
    n::Int = 0
    for Vk in V
        n += length(Vk)
    end
    i = findfirst(v -> isa(v, NullableArray), V)
    a = similar(full(V[i == 0 ? 1 : i]), T, n)
    pos = 1
    for k=1:length(V)
        Vk = V[k]
        p1 = pos+length(Vk)-1
        a[pos:p1] = Vk
        pos = p1+1
    end
    a
end

function Base.typed_vcat{T}(::Type{T}, A::AbstractMatrix...)
    nargs = length(A)
    nrows = sum(a->size(a, 1), A)::Int
    ncols = size(A[1], 2)
    for j = 2:nargs
        if size(A[j], 2) != ncols
            throw(ArgumentError("number of columns of each array must match (got $(map(x->size(x,2), A)))"))
        end
    end
    i = findfirst(a -> isa(a, NullableArray), A)
    B = similar(full(A[i == 0 ? 1 : i]), T, nrows, ncols)
    pos = 1
    for k=1:nargs
        Ak = A[k]
        p1 = pos+size(Ak,1)-1
        B[pos:p1, :] = Ak
        pos = p1+1
    end
    return B
end
