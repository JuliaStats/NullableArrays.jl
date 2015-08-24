@doc """
# Description

Construct a NullableArray from an array of values and a Boolean mask indicating
which values should be considered null.

# Args

* values: An array indicating the values taken on when entries are not null.
* isnull: An array indicating which entries are not null.

# Returns

* x::NullableArray{T, N}: A nullable array containing the specified values
    and missing the indicated entries.

# Examples

```
x = NullableArray([1, 2, 3], [false, false, false])
y = NullableArray([1, 2, 3])
```
""" ->
function NullableArray{T, N}(
    values::AbstractArray{T, N},
    isnull::Array{Bool, N} = fill(false, size(values)),
)
    NullableArray{T, N}(values, isnull)
end

@doc """
# Description

Construct a quasi-uninitialized `NullableArray` object by specifying the type
of its elements and its size as a tuple.

The result is quasi-uninitialized because the underlying memory for
representing values will be left uninitialized, but the `isnull` bitmask will
be initialized to false everywhere.

# Args

* T: The type of elements of the resulting `NullableArray`.
* dims: The size of the resulting `NullableArray` as a tuple.

# Returns

* x::NullableArray{T, N}: A nullable array of the specified type and size.

# Examples

```
x = NullableArray(Int64, (2, 2))
```
""" ->
function NullableArray{T}(::Type{T}, dims::Dims)
    NullableArray(Array(T, dims), fill(true, dims))
end

@doc """
# Description

Construct a quasi-uninitialized `NullableArray` object by specifying the type
of its elements and its size as a sequence of separate integer arguments.

The result is quasi-uninitialized because the underlying memory for
representing values will be left uninitialized, but the `isnull` bitmask will
be initialized to false everywhere.

# Args

* T: The type of elements of the resulting `NullableArray`.
* dims: The size of the resulting `NullableArray` as a sequence of integer
    arguments.

# Returns

* x::NullableArray{T, N}: A nullable array of the specified type and size.

# Examples

```
x = NullableArray(Int64, 2, 2)
```
""" ->
function NullableArray(T::Type, dims::Int...)
    return NullableArray(T, dims)
end

@doc """
# Description

Construct an empty `NullableArray` object by calling the name of the
fully parametrized type with zero arguments.

# Args

NONE

# Returns

* x::NullableArray{T, N}: An empty nullable array of the specified type.

# Examples

```
x = NullableArray{Int64, 2}()
```
""" ->
function Base.call{T, N}(::Type{NullableArray{T, N}})
    NullableArray(T, ntuple(i -> 0, N))
end

@doc """
# Description

Construct an empty `NullableVector` object by calling the name of the
fully parametrized type with zero arguments.

# Args

NONE

# Returns

* x::NullableVector{T}: An empty nullable vector of the specified type.

# Examples

```
x = NullableVector{Int64}()
```
""" ->
Base.call{T}(::Type{NullableVector{T}}) = NullableArray(T, (0, ))

@doc """
# Description

Construct an empty `NullableMatrix` object by calling the name of the
fully parametrized type with zero arguments.

# Args

NONE

# Returns

* x::NullableMatrix{T}: An empty nullable matrix of the specified type.

# Examples

```
x = NullableMatrix{Int64}()
```
""" ->
Base.call{T}(::Type{NullableMatrix{T}}) = NullableArray(T, (0, 0))

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
