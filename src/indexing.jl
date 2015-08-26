# NullableArray is dense and allows fast linear indexing.
import Base: LinearFast

#----- GENERAL INDEXING METHODS ----------------------------------------------#

Base.linearindexing{T <: NullableArray}(::Type{T}) = LinearFast()

# resolve ambiguity created by the two definitions that follow.
function Base.getindex{T, N}(X::NullableArray{T, N})
    return X
end

# Extract a scalar element from a `NullableArray`.
@inline function Base.getindex{T, N}(X::NullableArray{T, N}, I::Int...)
    if isbits(T)
        Nullable{T}(X.values[I...], X.isnull[I...])
    else
        if X.isnull[I...]
            Nullable{T}()
        else
            Nullable{T}(X.values[I...])
        end
    end
end

@inline function Base.getindex{T, N}(X::NullableArray{T, N},
                                     I::Nullable{Int}...)
    anynull(I) && throw(NullException())
    values = [ get(i) for i in I ]
    return getindex(X, values...)
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
    X.values[I...] = v
    X.isnull[I...] = false
    return v
end

#----- UNSAFE INDEXING METHODS -----------------------------------------------#

function unsafe_getindex_notnull(X::NullableArray, I::Int...)
    return Nullable(getindex(X.values, I...))
end

function unsafe_getvalue_notnull(X::NullableArray, I::Int...)
    return getindex(X.values, I...)
end

# ----- Base._checkbounds ----------------------------------------------------#

function Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, x::Nullable{T})
    isnull(x) ? throw(NullException()) : checkbounds(Bool, sz, get(x))
end

function Base.checkbounds(::Type{Bool}, sz::Int, I::NullableVector{Bool})
    anynull(I) && throw(NullException())
    length(I) == sz
end

function Base.checkbounds{T<:Real}(::Type{Bool}, sz::Int, I::NullableArray{T})
    inbounds = true
    anynull(I) && throw(NullException())
    for i in 1:length(I)
        @inbounds v = unsafe_getvalue_notnull(I, i)
        inbounds &= checkbounds(Bool, sz, v)
    end
    return inbounds
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
