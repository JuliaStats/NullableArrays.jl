
# ----- Constructors -------------------------------------------------------- #

# The following allows for construction of a NullableArray without explicit
# specification of type parameters;
# see docs.julialang.org/en/latest/manual/constructors/#parametric-constructors
function NullableArray{T, N}(A::AbstractArray{T, N}, m::Array{Bool, N}) # -> NullableArray
    return NullableArray{T, N}(A, m)
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
    return NullableArray(Array(T, dims), fill(true, dims))
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
function NullableArray{T, N}(A::AbstractArray{T, N}) # -> NullableArray
    return NullableArray{T, N}(A, fill(false, size(A)))
end

# The following method constructs a NullableArray from an Array{Any} argument
# 'A' that contains some placeholder of type 'T' for null values.
#
# e.g.: julia> NullableArray([1, nothing, 2], Void)
#       3-element NullableArrays.NullableArray{Int64,1}:
#       Nullable(1)
#       Nullable{Int64}()
#       Nullable(2)
#
#       julia> NullableArray([1, "notdefined", 2], ASCIIString)
#       3-element NullableArrays.NullableArray{Int64,1}:
#       Nullable(1)
#       Nullable{Int64}()
#       Nullable(2)
#
# TODO: think about dispatching on T = Any in method above to call
# the following method passing 'T=Void' for pseudo-literal
# NullableArray construction
function NullableArray{T, U}(A::Array, ::Type{T}, ::Type{U})
    _isnull = fill(true, size(A))
    _values = Array(T, size(A))
    @inbounds for (i, value) in enumerate(A)
        if !isa(value, U)
            setindex!(_isnull, false, i)
        end
    end
    @inbounds for (i, isnull) in enumerate(_isnull)
        !isnull && setindex!(_values, A[i], i)
    end
    return NullableArray(_isnull, _values)
end
