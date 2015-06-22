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

function Base.shift!{T}(X::NullableVector{T})
    val, isnull = shift!(X.values), shift!(X.isnull)
    if isnull
        return Nullable{T}()
    else
        return Nullable{T}(val)
    end
end

#----- Base.splice! ----------------------------------------------------------#


# ----- Base.reverse/Base.reverse! -------------------------------------------#

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
    return reverse!(copy(X))
end
