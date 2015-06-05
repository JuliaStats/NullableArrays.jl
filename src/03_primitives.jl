# We determine the size of a NullableArray array using the size of its
# `values` field. We could equivalently use the `.isnull` field.
Base.size(X::NullableArray) = size(X.values)

# Allocate a similar array
function Base.similar{T <: Nullable}(X::NullableArray, ::Type{T}, dims::Dims)
    NullableArray(eltype(T), dims)
end

# Allocate a similar array
Base.similar(X::NullableArray, T, dims::Dims) = NullableArray(T, dims)
