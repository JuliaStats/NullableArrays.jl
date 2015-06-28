#----- head/tail -------------------------------------------------------------#

head(X::NullableArray) = X[1:min(6, length(X))]
tail(X::NullableArray) = X[max(1, length(X) - 5):length(X)]

#----- Base.push! ------------------------------------------------------------#

function Base.push!{T, V}(X::NullableVector{T}, v::V)
    push!(X.values, v)
    push!(X.isnull, false)
    return X
end

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

#----- Base.pop! -------------------------------------------------------------#

function Base.pop!{T}(X::NullableVector{T}) # -> T
    val, isnull = pop!(X.values), pop!(X.isnull)
    isnull ? Nullable{T}() : Nullable(val)
end

#----- Base.unshift! ---------------------------------------------------------#

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

function Base.unshift!(X::NullableVector, v) # -> NullableVector{T}
    unshift!(X.values, v)
    unshift!(X.isnull, false)
    return X
end

function Base.unshift!(X::NullableVector, vs...)
    return unshift!(unshift!(X, last(vs)), vs[1:endof(vs)-1]...)
end

#----- Base.shift! -----------------------------------------------------------#

function Base.shift!{T}(X::NullableVector{T}) # -> Nullable{T}
    val, isnull = shift!(X.values), shift!(X.isnull)
    if isnull
        return Nullable{T}()
    else
        return Nullable{T}(val)
    end
end

#----- Base.splice! ----------------------------------------------------------#

const _default_splice = []

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

    for k = 1:endof(ins)
        X[f + k - 1] = ins[k]
    end
    return vs
end

#----- Base.deleteat! ---------------------------------------------------------#

function Base.deleteat!(X::NullableVector, inds)
    deleteat!(X.values, inds)
    deleteat!(X.isnull, inds)
    return X
end

#----- Base.append! ----------------------------------------------------------#

function Base.append!(X::NullableVector, items::AbstractVector)
    old_length = length(X)
    nitems = length(items)
    resize!(X, old_length + nitems)
    X[old_length + 1:end] = items[1:nitems]
    return X
end

#----- Base.sizehint! --------------------------------------------------------#

function Base.sizehint!(X::NullableVector, newsz::Integer)
    sizehint!(X.values, newsz)
    sizehint!(X.isnull, newsz)
end

#----- padnull!/padnull ------------------------------------------------------#

function padnull!{T}(X::NullableVector{T}, front::Integer, back::Integer)
    unshift!(X, fill(Nullable{T}(), front)...)
    append!(X, fill(Nullable{T}(), back))
    return X
end

function padnull(X::NullableVector, front::Integer, back::Integer)
    return padnull!(copy(X), front, back)
end

#----- Base.reverse/Base.reverse! --------------------------------------------#

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
            else
                if !X.isnull[r]
                    X.values[i] = X.values[r]
                end
            end
            r -= 1
        end
        reverse!(X.isnull, s, n)
    end
    return X
end

function Base.reverse(X::NullableVector, s=1, n=length(X))
    return reverse!(copy(X), s, n)
end
