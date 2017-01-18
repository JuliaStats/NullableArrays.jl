# NullableArray is dense and allows fast linear indexing.
import Base: LinearFast

@compat Base.IndexStyle(::Type{<:NullableArray}) = IndexLinear()

# resolve ambiguity created by the two definitions that follow.
function Base.getindex{T, N}(X::NullableArray{T, N})
    return X[1]
end

"""
    getindex{T, N}(X::NullableArray{T, N}, I::Int...)

Retrieve a single entry from a `NullableArray`. If the value in the entry
designated by `I` is present, then it will be returned wrapped in a
`Nullable{T}` container. If the value is missing, then this method returns
`Nullable{T}()`.
"""
# Extract a scalar element from a `NullableArray`.
@inline function Base.getindex{T, N}(X::NullableArray{T, N}, I::Int...)
    if isbits(T)
        ifelse(X.isnull[I...], Nullable{T}(), Nullable{T}(X.values[I...]))
    else
        if X.isnull[I...]
            Nullable{T}()
        else
            Nullable{T}(X.values[I...])
        end
    end
end

"""
    getindex{T, N}(X::NullableArray{T, N}, I::Nullable{Int}...)

Just as above, with the additional behavior that this method throws an error if
any component of the index `I` is null.
"""
@inline function Base.getindex{T, N}(X::NullableArray{T, N},
                                     I::Nullable{Int}...)
    any(isnull, I) && throw(NullException())
    values = [ get(i) for i in I ]
    return getindex(X, values...)
end

"""
    setindex!(X::NullableArray, v::Nullable, I::Int...)

Set the entry of `X` at position `I` equal to a `Nullable` value `v`. If
`v` is null, then only `X.isnull` is updated to indicate that the entry at
index `I` is null. If `v` is not null, then `X.isnull` is updated to indicate
that the entry at index `I` is present and `X.values` is updated to store the
value wrapped in `v`.
"""
# Insert a scalar element from a `NullableArray` from a `Nullable` value.
@inline function Base.setindex!(X::NullableArray, v::Nullable, I::Int...)
    if isnull(v)
        X.isnull[I...] = true
    else
        X.isnull[I...] = false
        X.values[I...] = get(v)
    end
    return v
end

"""
    setindex!(X::NullableArray, v::Any, I::Int...)

Set the entry of `X` at position `I` equal to `v`. This method always updates
`X.isnull` to indicate that the entry at index `I` is present and `X.values`
to store `v` at `I`.
"""
# Insert a scalar element from a `NullableArray` from a non-Nullable value.
@inline function Base.setindex!(X::NullableArray, v::Any, I::Int...)
    X.values[I...] = v
    X.isnull[I...] = false
    return v
end

# return the value of non-null X element wrapped in Nullable
@inline function unsafe_getindex_notnull(X::NullableArray, I::Int...)
    return Nullable(getindex(X.values, I...))
end
@inline function unsafe_getindex_notnull{T}(X::AbstractArray{Nullable{T}}, I::Int...)
    return getindex(X, I...)
end

# return the value of non-null X element
@inline function unsafe_getvalue_notnull(X::NullableArray, I::Int...)
    return getindex(X.values, I...)
end
@inline function unsafe_getvalue_notnull{T}(X::AbstractArray{Nullable{T}}, I::Int...)
    return get(getindex(X, I...))
end

if VERSION >= v"0.5.0-dev+4697"
    function Base.checkindex(::Type{Bool}, inds::AbstractUnitRange, i::Nullable)
        isnull(i) ? throw(NullException()) : checkindex(Bool, inds, get(i))
    end

    function Base.checkindex{N}(::Type{Bool}, inds::AbstractUnitRange, I::NullableArray{Bool, N})
        any(isnull, I) && throw(NullException())
        checkindex(Bool, inds, I.values)
    end

    function Base.checkindex{T<:Real}(::Type{Bool}, inds::AbstractUnitRange, I::NullableArray{T})
        any(isnull, I) && throw(NullException())
        b = true
        for i in 1:length(I)
            @inbounds v = unsafe_getvalue_notnull(I, i)
            b &= checkindex(Bool, inds, v)
        end
        return b
    end
else
    function Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, x::Nullable{T})
        isnull(x) ? throw(NullException()) : checkbounds(Bool, sz, get(x))
     end

    function Base.checkbounds(::Type{Bool}, sz::Int, I::NullableVector{Bool})
        any(isnull, I) && throw(NullException())
        length(I) == sz
    end

    function Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, I::NullableArray{T})
        inbounds = true
        any(isnull, I) && throw(NullException())
        for i in 1:length(I)
             @inbounds v = unsafe_getvalue_notnull(I, i)
            inbounds &= checkbounds(Bool, sz, v)
        end
        return inbounds
     end
end

function Base.to_index(X::NullableArray)
    any(isnull, X) && throw(NullException())
    Base.to_index(X.values)
end

"""
    nullify!(X::NullableArray, I...)

This is a convenience method to set the entry of `X` at index `I` to be null
"""
@inline function nullify!(X::NullableArray, I...)
    setindex!(X, Nullable{eltype(X)}(), I...)
end
