# NullableArray is dense and allows fast linear indexing.
import Base: LinearFast

#----- GENERAL INDEXING METHODS ----------------------------------------------#

Base.linearindexing{T <: NullableArray}(::Type{T}) = LinearFast()

# Extract a scalar element from a `NullableArray`.
@inline function Base.getindex{T, N}(X::NullableArray{T, N}, I::Int...)
    if X.isnull[I...]
        Nullable{T}()
    else
        Nullable{T}(X.values[I...])
    end
end

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

# Insert a scalar element from a `NullableArray` from a non-Nullable value.
@inline function Base.setindex!(X::NullableArray, v::Any, I::Int...)
    X.isnull[I...] = false
    X.values[I...] = v
    return v
end

#----- UNSAFE INDEXING METHODS -----------------------------------------------#

function unsafe_getindex_notnull(X::NullableArray, I::Int...)
    return getindex(X, I...)
end

function unsafe_getvalue_notnull(X::NullableArray, I::Int...)
    return getindex(X.values, I...)
end

# ----- Base._checkbounds ----------------------------------------------------#

function Base._checkbounds{T <: Real}(sz::Int, x::Nullable{T})
    isnull(x) ? throw(NullException()) : _checkbounds(sz, get(x))
end

function Base._checkbounds(sz::Int, I::NullableVector{Bool})
    length(I) == sz || throw(BoundsError())
end

function Base._checkbounds{T<:Real}(sz::Int, I::NullableArray{T})
    anynull(I) && throw(NullException())
    for i in 1:length(I)
        @inbounds v = unsafe_getvalue_notnull(I, i)
        checkbounds(sz, v)
    end
end

# ----- Base.to_index --------------------------------------------------------#

function Base.to_index(X::NullableArray)
    anynull(X) && throw(NullException())
    Base.to_index(X.values)
end

# ----- nullify! --------------------------------------------------------------#

function nullify!(X::NullableArray, I...)
    setindex!(X, Nullable{eltype(X)}(), I...)
end
