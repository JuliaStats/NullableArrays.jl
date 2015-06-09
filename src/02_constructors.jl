
# ----- Constructors -------------------------------------------------------- #

# The following allows for construction of a NullableArray without explicit
# specification of type parameters;
# see docs.julialang.org/en/latest/manual/constructors/#parametric-constructors
function NullableArray(m::AbstractArray, a::AbstractArray) # -> NullableArray
    return NullableArray{eltype(a), ndims(a)}(m, a)
end

# TODO: Uncomment this doc entry when Base Julia can parse it correctly.
# @doc """
# Allow users to construct a quasi-uninitialized `NullableArray` object by
# specifing:
#
# * `T`: The type of its elements.
# * `dims`: The size of the resulting `NullableArray`.
#
# NOTE: The `values` field will be truly uninitialized, but the `isnull` field
# will be initialized to `true` everywhere, making every entry of a new
# `NullableArray` a null value by default.
# """ ->
function NullableArray{T}(::Type{T}, dims::Dims) # -> NullableArray
    return NullableArray(fill(true, dims), Array(T, dims))
end

# Constructs an empty NullableArray of type parameter T and number of dimensions
# equal to the number of arguments given in 'dims...', where the latter are
# dimension lengths.
function NullableArray(T::Type, dims::Int...) # -> NullableArray
    return NullableArray(T, dims)
end

# Constructs a NullableArray from an Array 'a' of values and an optional
# Array{Bool, N} mask. If omitted, the mask will default to an array of
# 'false's the size of 'a'.
function NullableArray{T, N}(a::AbstractArray{T, N}) # -> NullableArray
    return NullableArray{T, N}(fill(false, size(a)), a)
end
