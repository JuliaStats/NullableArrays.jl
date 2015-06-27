
# ----- Outer Constructors -------------------------------------------------- #

# ----- Constructor #1
# The following provides an outer constructor whose argument signature matches
# that of the inner constructor provided in 01_typedefs.jl.
function NullableArray{T, N}(A::AbstractArray{T, N},
                             m::Array{Bool, N}) # -> NullableArray{T, N}
    return NullableArray{T, N}(A, m)
end

# ----- Constructor #2 -------------------------------------------------------#
# Constructs a NullableArray from an Array 'a' of values and an optional
# Array{Bool, N} mask. If omitted, the mask will default to an array of
# 'false's the size of 'a'.
function NullableArray{T, N}(A::AbstractArray{T, N}) # -> NullableArray{T, N}
    return NullableArray{T, N}(A, fill(false, size(A)))
end

# ----- Constructor #3 -------------------------------------------------------#
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
function NullableArray{T}(::Type{T}, dims::Dims) # -> NullableArray{T, N}
    return NullableArray(Array(T, dims), fill(true, dims))
end

# ----- Constructor #4 -------------------------------------------------------#
# Constructs an empty NullableArray of type parameter T and number of dimensions
# equal to the number of arguments given in 'dims...', where the latter are
# dimension lengths.
function NullableArray(T::Type, dims::Int...) # -> NullableArray
    return NullableArray(T, dims)
end

# ----- Constructor #5 -------------------------------------------------------#
# The following method constructs a NullableArray from an Array{Any} argument
# 'A' that contains some placeholder of type 'T' for null values.
#
# e.g.: julia> NullableArray([1, nothing, 2], Int, Void)
#       3-element NullableArrays.NullableArray{Int64,1}:
#       Nullable(1)
#       Nullable{Int64}()
#       Nullable(2)
#
#       julia> NullableArray([1, "notdefined", 2], Int, ASCIIString)
#       3-element NullableArrays.NullableArray{Int64,1}:
#       Nullable(1)
#       Nullable{Int64}()
#       Nullable(2)
#
# TODO: think about dispatching on T = Any in method above to call
# the following method passing 'T=Void' for pseudo-literal
# NullableArray construction
function NullableArray{T, U}(A::AbstractArray,
                             ::Type{T}, ::Type{U}) # -> NullableArray{T, N}
    res = NullableArray(T, size(A))
    for i in 1:length(A)
        if !isa(A[i], U)
            @inbounds setindex!(res, A[i], i)
        end
    end
    return res
end

# ----- Constructor #6 -------------------------------------------------------#
# The following method constructs a NullableArray from an Array{Any} argument
# `A` that contains some placeholder value `na` for null values.
#
# e.g.: julia> NullableArray(Any[1, "na", 2], Int, "na")
#       3-element NullableArrays.NullableArray{Int64,1}:
#       Nullable(1)
#       Nullable{Int64}()
#       Nullable(2)
#
function NullableArray{T}(A::AbstractArray,
                             ::Type{T},
                             na::Any;
                             conversion::Base.Callable=Base.convert) # -> NullableArray{T, N}
    res = NullableArray(T, size(A))
    for i in 1:length(A)
        if !isequal(A[i], na)
            @inbounds setindex!(res, A[i], i)
        end
    end
    return res
end

#----- Constructor #7 --------------------------------------------------------#

# The following method allows for the construction of zero-element
# NullableArrays by calling the parametrized type on zero arguments.
# TODO: add support for dimensions arguments?
function Base.call{T, N}(::Type{NullableArray{T, N}})
    NullableArray(T, ntuple(i->0, N))
end
