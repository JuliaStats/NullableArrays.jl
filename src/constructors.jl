
# ----- Outer Constructors -------------------------------------------------- #

# The following provides an outer constructor whose argument signature matches
# that of the inner constructor provided in typedefs.jl: constructs a NullableArray
# from an Array of values and an Array{Bool} mask.
function NullableArray{T, N}(A::AbstractArray{T, N},
                             m::Array{Bool, N}) # -> NullableArray{T, N}
    return NullableArray{T, N}(A, m)
end

# TODO: Uncomment this doc entry when Base Julia can parse it correctly.
# """
# Allow users to construct a quasi-uninitialized `NullableArray` object by
# specifing:
#
# * `T`: The type of its elements.
# * `dims`: The size of the resulting `NullableArray`.
#
# NOTE: The `values` field will be truly uninitialized, but the `isnull` field
# will be initialized to `true` everywhere, making every entry of a new
# `NullableArray` a null value by default.
# """
function NullableArray{T}(::Type{T}, dims::Dims) # -> NullableArray{T, N}
    return NullableArray(Array(T, dims), fill(true, dims))
end

# Constructs an empty NullableArray of type parameter T and number of dimensions
# equal to the number of arguments given in 'dims...', where the latter are
# dimension lengths.
function NullableArray(T::Type, dims::Int...) # -> NullableArray
    return NullableArray(T, dims)
end

@compat (::Type{NullableArray{T}}){T}(dims::Dims) = NullableArray(T, dims)
@compat (::Type{NullableArray{T}}){T}(dims::Int...) = NullableArray(T, dims)
if VERSION >= v"0.5.0-"
    @compat (::Type{NullableArray{T,N}}){T,N}(dims::Vararg{Int,N}) = NullableArray(T, dims)
else
    function Base.convert{T,N}(::Type{NullableArray{T,N}}, dims::Int...)
        length(dims) == N || throw(ArgumentError("Wrong number of arguments. Expected $N, got $(length(dims))."))
        NullableArray(T, dims)
    end
end

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
                             na::Any) # -> NullableArray{T, N}
    res = NullableArray(T, size(A))
    for i in 1:length(A)
        if !isequal(A[i], na)
            @inbounds setindex!(res, A[i], i)
        end
    end
    return res
end

# The following method allows for the construction of zero-element
# NullableArrays by calling the parametrized type on zero arguments.
@compat (::Type{NullableArray{T, N}}){T, N}() = NullableArray(T, ntuple(i->0, N))


# ----- Conversion to NullableArrays ---------------------------------------- #
# Also provides constructors from arrays via the fallback mechanism.

#----- Conversion from arrays (of non-Nullables) -----------------------------#
function Base.convert{S, T, N}(::Type{NullableArray{T, N}},
                               A::AbstractArray{S, N}) # -> NullableArray{T, N}
    NullableArray{T, N}(convert(AbstractArray{T, N}, A), fill(false, size(A)))
end

function Base.convert{S, T, N}(::Type{NullableArray{T}},
                               A::AbstractArray{S, N}) # -> NullableArray{T, N}
    convert(NullableArray{T, N}, A)
end

function Base.convert{T, N}(::Type{NullableArray},
                            A::AbstractArray{T, N}) # -> NullableArray{T, N}
    convert(NullableArray{T, N}, A)
end

#----- Conversion from arrays of Nullables -----------------------------------#
function Base.convert{S<:Nullable, T, N}(::Type{NullableArray{T, N}},
                                         A::AbstractArray{S, N}) # -> NullableArray{T, N}
   out = NullableArray{T, N}(Array(T, size(A)), Array(Bool, size(A)))
   for i = 1:length(A)
       if !(out.isnull[i] = isnull(A[i]))
           out.values[i] = A[i].value
       end
   end
   out
end

#----- Conversion from NullableArrays of a different type --------------------#
Base.convert{T, N}(::Type{NullableArray}, X::NullableArray{T,N}) = X

function Base.convert{S, T, N}(::Type{NullableArray{T}},
                               A::AbstractArray{Nullable{S}, N}) # -> NullableArray{T, N}
    convert(NullableArray{T, N}, A)
end

function Base.convert{T, N}(::Type{NullableArray},
                            A::AbstractArray{Nullable{T}, N}) # -> NullableArray{T, N}
    convert(NullableArray{T, N}, A)
end

function Base.convert{N}(::Type{NullableArray},
                         A::AbstractArray{Nullable, N}) # -> NullableArray{Any, N}
    convert(NullableArray{Any, N}, A)
end

function Base.convert{S, T, N}(::Type{NullableArray{T, N}},
                               A::NullableArray{S, N}) # -> NullableArray{T, N}
    NullableArray(convert(AbstractArray{T, N}, A.values), A.isnull)
end
