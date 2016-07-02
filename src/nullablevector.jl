@doc """
`push!{T, V}(X::NullableVector{T}, v::V)`

Insert `v` at the end of `X`, which registers `v` as a present value.
""" ->
function Base.push!{T, V}(X::NullableVector{T}, v::V)
    push!(X.values, v)
    push!(X.isnull, false)
    return X
end

@doc """
`push!{T, V}(X::NullableVector{T}, v::Nullable{V})`

Insert a value at the end of `X` from a `Nullable` value `v`. If `v` is null
then this method adds a null entry at the end of `X`. Returns `X`.
""" ->
function Base.push!{T, V}(X::NullableVector{T}, v::Nullable{V})
    if v.isnull
        resize!(X.values, length(X.values) + 1)
        push!(X.isnull, true)
    else
        push!(X.values, v.value)
        push!(X.isnull, false)
    end
    return X
end

@doc """
`pop!{T}(X::NullableVector{T})`

Remove the last entry from `X` and return it. If the value in that entry is
missing, then this method returns `Nullable{T}()`.
""" ->
function Base.pop!{T}(X::NullableVector{T}) # -> T
    val, isnull = pop!(X.values), pop!(X.isnull)
    isnull ? Nullable{T}() : Nullable(val)
end

@doc """
`unshift!(X::NullableVector, v::Nullable)`

Insert a value at the beginning of `X` from a `Nullable` value `v`. If `v` is
null then this method inserts a null entry at the beginning of `X`. Returns `X`.
""" ->
function Base.unshift!(X::NullableVector, v::Nullable) # -> NullableVector{T}
    if v.isnull
        ccall(:jl_array_grow_beg, Void, (Any, UInt), X.values, 1)
        unshift!(X.isnull, true)
    else
        unshift!(X.values, v.value)
        unshift!(X.isnull, false)
    end
    return X
end

@doc """
`unshift!(X::NullableVector, v::Nullable)`

Insert a value `v` at the beginning of `X` and return `X`.
""" ->
function Base.unshift!(X::NullableVector, v) # -> NullableVector{T}
    unshift!(X.values, v)
    unshift!(X.isnull, false)
    return X
end

@doc """
`unshift!(X::NullableVector, vs...)`

Insert multiple values `vs` at the beginning of `X` and return `X`.
""" ->
function Base.unshift!(X::NullableVector, vs...)
    return unshift!(unshift!(X, last(vs)), vs[1:endof(vs)-1]...)
end

@doc """
`shift!{T}(X::NullableVector{T})`

Remove the first entry from `X` and return it as a `Nullable` object.
""" ->
function Base.shift!{T}(X::NullableVector{T}) # -> Nullable{T}
    val, isnull = shift!(X.values), shift!(X.isnull)
    if isnull
        return Nullable{T}()
    else
        return Nullable{T}(val)
    end
end

const _default_splice = []

@doc """
`splice!(X::NullableVector, i::Integer, [ins])`

Remove the item at index `i` and return the removed item. Subsequent items
are shifted down to fill the resulting gap. If specified, replacement values from
an ordered collection will be spliced in place of the removed item.
""" ->
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

@doc """
`splice!{T<:Integer}(X::NullableVector, rng::UnitRange{T}, [ins])`

Remove items in the specified index range, and return a collection containing
the removed items. Subsequent items are shifted down to fill the resulting gap.
If specified, replacement values from an ordered collection will be spliced in
place of the removed items.

To insert `ins` before an index `n` without removing any items, use
`splice!(X, n:n-1, ins)`.
""" ->
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

@doc """
`deleteat!(X::NullableVector, inds)`

Delete the entry at `inds` from `X` and then return `X`. Note that `inds` may
be either a single scalar index or a collection of sorted, pairwise unique
indices. Subsequent items after deleted entries are shifted down to fill the
resulting gaps.
""" ->
function Base.deleteat!(X::NullableVector, inds)
    deleteat!(X.values, inds)
    deleteat!(X.isnull, inds)
    return X
end

@doc """
`append!(X::NullableVector, items::AbstractVector)`

Add the elements of `items` to the end of `X`.

Note that `append!(X, [1, 2, 3])` is equivalent to `push!(X, 1, 2, 3)`,
where the items to be added to `X` are passed individually to `push!` and as a
collection to `append!`.
""" ->
function Base.append!(X::NullableVector, items::AbstractVector)
    old_length = length(X)
    nitems = length(items)
    resize!(X, old_length + nitems)
    X[old_length + 1:end] = items[1:nitems]
    return X
end

@doc """
`sizehint!(X::NullableVector, newsz::Integer)`

Suggest that collection `X` reserve capacity for at least `newsz` elements.
This can improve performance.
""" ->
function Base.sizehint!(X::NullableVector, newsz::Integer)
    sizehint!(X.values, newsz)
    sizehint!(X.isnull, newsz)
end

@doc """
`padnull!(X::NullableVector, front::Integer, back::Integer)`

Insert `front` null entries at the beginning of `X` and add `back` null entries
at the end of `X`. Returns `X`.
""" ->
function padnull!{T}(X::NullableVector{T}, front::Integer, back::Integer)
    unshift!(X, fill(Nullable{T}(), front)...)
    append!(X, fill(Nullable{T}(), back))
    return X
end

@doc """
`padnull(X::NullableVector, front::Integer, back::Integer)`

return a copy of `X` with `front` null entries inserted at the beginning of
the copy and `back` null entries inserted at the end.
""" ->
function padnull(X::NullableVector, front::Integer, back::Integer)
    return padnull!(copy(X), front, back)
end

@doc """
`reverse!(X::NullableVector, [s], [n])`

Modify `X` by reversing the first `n` elements starting at index `s`
(inclusive). If unspecified, `s` and `n` will default to `1` and `length(X)`,
respectively.
""" ->
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

@doc """
`reverse(X::NullableVector, [s], [n])`

Return a copy of `X` with the first `n` elements starting at index `s`
(inclusive) reversed. If unspecified, `s` and `n` will default to `1` and
`length(X)`, respectively.
""" ->
function Base.reverse(X::NullableVector, s=1, n=length(X))
    return reverse!(copy(X), s, n)
end
