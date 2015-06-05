# NullableArray is dense and allows fast linear indexing.
import Base: LinearFast

Base.linearindexing{T <: NullableArray}(::Type{T}) = LinearFast()

# Extract a scalar element from a `NullableArray`.
function Base.getindex{T, N}(X::NullableArray{T, N}, I::Int...)
    if X.isnull[I...]
        Nullable{T}()
    else
        Nullable{T}(X.values[I...])
    end
end

# Insert a scalar element from a `NullableArray` from a `Nullable` value.
function Base.setindex!(X::NullableArray, v::Nullable, I::Int...)
    if isnull(v)
        X.isnull[I...] = true
    else
        X.isnull[I...] = false
        X.values[I...] = get(v)
    end
    v
end

# Insert a scalar element from a `NullableArray` from a non-Nullable value.
function Base.setindex!(X::NullableArray, v::Any, I::Int...)
    X.isnull[I...] = false
    X.values[I...] = v
    v
end
