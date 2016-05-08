Base.isnull(X::NullableArray, I::Int...) = X.isnull[I...]
Base.values(X::NullableArray, I::Int...) = X.values[I...]

@doc """
`size(X::NullableArray, [d::Real])`

Return a tuple containing the lengths of each dimension of `X`, or if `d` is
specific, the length of `X` along dimension `d`.
""" ->
Base.size(X::NullableArray) = size(X.values) # -> NTuple{Int}

@doc """
`similar(X::NullableArray, [T], [dims])`

Allocate an uninitialized `NullableArray` of element type `T` and with
size `dims`. If unspecified, `T` and `dims` default to the element type and size
equal to that of `X`.
""" ->
function Base.similar{T<:Nullable}(X::NullableArray, ::Type{T}, dims::Dims)
    NullableArray(eltype(T), dims)
end

# @doc """
#
# """ ->
Base.similar(X::NullableArray, T, dims::Dims) = NullableArray(T, dims)

@doc """
`copy(X::NullableArray)`

Return a shallow copy of `X`; the outer structure of `X` will be copied, but
all elements will be identical to those of `X`.
""" ->
Base.copy(X::NullableArray) = Base.copy!(similar(X), X)

@doc """
`copy!(dest::NullableArray, src::NullableArray)`

Copy the initialized values of a source NullableArray into the respective
indices of the destination NullableArray. If an entry in `src` is null, then
this method nullifies the respective entry in `dest`.
""" ->
function Base.copy!(dest::NullableArray,
                    src::NullableArray) # -> NullableArray{T, N}
    if isbits(eltype(dest)) && isbits(eltype(src))
        copy!(dest.values, src.values)
    else
        dest_values = dest.values
        src_values = src.values
        length(dest_values) >= length(src_values) || throw(BoundsError())
        # copy only initilialized values from src into dest
        for i in 1:length(src_values)
            @inbounds !(src.isnull[i]) && (dest.values[i] = src.values[i])
        end
    end
    copy!(dest.isnull, src.isnull)
    return dest
end

@doc """
`fill!(X::NullableArray, x::Nullable)`

Fill `X` with the value `x`. If `x` is empty, then `fill!(X, x)` nullifies each
entry of `X`. Otherwise, `fill!(X, x)` fills `X.values` with the value of `x`
and designates each entry of `X` as present.
""" ->
function Base.fill!(X::NullableArray, x::Nullable) # -> NullableArray{T, N}
    if isnull(x)
        fill!(X.isnull, true)
    else
        fill!(X.values, get(x))
        fill!(X.isnull, false)
    end
    return X
end

@doc """
`fill!(X::NullableArray, x::Nullable)`

Fill `X` with the value `x` and designate each entry as present. If `x` is an
object reference, all elements will refer to the same object. Note that
`fill!(X, Foo())` will return `X` filled with the result of evaluating `Foo()`
once.
""" ->
function Base.fill!(X::NullableArray, x::Any) # -> NullableArray{T, N}
    fill!(X.values, x)
    fill!(X.isnull, false)
    return X
end

@doc """
`Base.deepcopy(X::NullableArray)`

Return a `NullableArray` object whose internal `values` and `isnull` fields are
deep copies of `X.values` and `X.isnull` respectively.
""" ->
function Base.deepcopy(X::NullableArray) # -> NullableArray{T}
    return NullableArray(deepcopy(X.values), deepcopy(X.isnull))
end

@doc """
`resize!(X::NullableVector, n::Int)`

Resize a one-dimensional `NullableArray` `X` to contain precisely `n` elements.
If `n` is greater than the current length of `X`, then each new entry will be
designated as null.
""" ->
function Base.resize!{T}(X::NullableArray{T,1}, n::Int) # -> NullableArray{T, 1}
    resize!(X.values, n)
    oldn = length(X.isnull)
    resize!(X.isnull, n)
    X.isnull[oldn+1:n] = true
    return X
end

@doc """
`ndims(X::NullableArray)`

Returns the number of dimensions of `X`.
""" ->
Base.ndims(X::NullableArray) = ndims(X.values) # -> Int

@doc """
`length(X::NullableArray)`

Returns the maximum index `i` for which `getindex(X, i)` is valid.
""" ->
Base.length(X::NullableArray) = length(X.values) # -> Int

@doc """
`endof(X::NullableArray)`

Returns the last entry of `X`.
""" ->
Base.endof(X::NullableArray) = endof(X.values) # -> Int

@doc """

""" ->
function Base.find(X::NullableArray{Bool}) # -> Array{Int}
    ntrue = 0
    @inbounds for (i, isnull) in enumerate(X.isnull)
        ntrue += !isnull && X.values[i]
    end
    res = Array(Int, ntrue)
    ind = 1
    @inbounds for (i, isnull) in enumerate(X.isnull)
        if !isnull && X.values[i]
            res[ind] = i
            ind += 1
        end
    end
    return res
end

@doc """
`dropnull(X::NullableVector)`

Return a `Vector` containing only the non-null entries of `X`.
""" ->
dropnull(X::NullableVector) = copy(X.values[!X.isnull]) # -> Vector{T}

@doc """
`anynull(X::NullableArray)`

Returns whether or not any entries of `X` are null.
""" ->
anynull(X::NullableArray) = any(X.isnull) # -> Bool

# @doc """
#
# """ ->
# NOTE: the following currently short-circuits.
function anynull(A::AbstractArray) # -> Bool
    for a in A
        if isa(a, Nullable)
            a.isnull && (return true)
        end
    end
    return false
end
#
# @doc """
#
# """ ->
function anynull(xs::NTuple) # -> Bool
    for x in xs
        if isa(x, Nullable)
            x.isnull && (return true)
        end
    end
    return false
end

@doc """
`allnull(X::NullableArray)`

Returns whether or not all the entries in `X` are null.
""" ->
allnull(X::NullableArray) = all(X.isnull) # -> Bool

@doc """
`isnan(X::NullableArray)`

Test whether each entry of `X` is null and if not, test whether the entry is
not a number (`NaN`). Return the results as `NullableArray{Bool}`. Note that
null entries of `X` will be reflected by null entries of the resultant
`NullableArray`.
""" ->
function Base.isnan(X::NullableArray) # -> NullableArray{Bool}
    return NullableArray(isnan(X.values), copy(X.isnull))
end

@doc """
`isfinite(X::NullableArray)`

Test whether each entry of `X` is null and if not, test whether the entry is
finite. Return the results as `NullableArray{Bool}`. Note that
null entries of `X` will be reflected by null entries of the resultant
`NullableArray`.
""" ->
function Base.isfinite(X::NullableArray) # -> NullableArray{Bool}
    res = Array(Bool, size(X))
    for i in eachindex(X)
        if !X.isnull[i]
            res[i] = isfinite(X.values[i])
        end
    end
    return NullableArray(res, copy(X.isnull))
end

@doc """
`convert(T, X::NullableArray)`

Convert `X` to an `AbstractArray` of type `T`. Note that if `X` contains any
null entries then calling `convert` without supplying a replacement value for
null entries will result in an error.

Currently supported return type arguments include: `Array`, `Array{T}`,
`Vector`, `Matrix`.

`convert(T, X::NullableArray, replacement)`

Convert `X` to an `AbstractArray` of type `T` and replace all null entries of
`X` with `replacement` in the result.
""" ->
function Base.convert{S, T, N}(::Type{Array{S, N}},
                               X::NullableArray{T, N}) # -> Array{S, N}
    if anynull(X)
        throw(NullException())
    else
        return convert(Array{S, N}, X.values)
    end
end

function Base.convert{S, T, N}(::Type{Array{S}},
                               X::NullableArray{T, N}) # -> Array{S, N}
    return convert(Array{S, N}, X)
end

function Base.convert{T}(::Type{Vector}, X::NullableVector{T}) # -> Vector{T}
    return convert(Array{T, 1}, X)
end

function Base.convert{T}(::Type{Matrix}, X::NullableMatrix{T}) # -> Matrix{T}
    return convert(Array{T, 2}, X)
end

function Base.convert{T, N}(::Type{Array},
                            X::NullableArray{T, N}) # -> Array{T, N}
    return convert(Array{T, N}, X)
end

# Conversions with replacements for handling null values

function Base.convert{S, T, N}(::Type{Array{S, N}},
                               X::NullableArray{T, N},
                               replacement::Any) # -> Array{S, N}
    replacementS = convert(S, replacement)
    res = Array(S, size(X))
    for i in 1:length(X)
        if X.isnull[i]
            res[i] = replacementS
        else
            res[i] = X.values[i]
        end
    end
    return res
end

function Base.convert{T}(::Type{Vector},
                         X::NullableVector{T},
                         replacement::Any) # -> Vector{T}
    return convert(Array{T, 1}, X, replacement)
end

function Base.convert{T}(::Type{Matrix},
                         X::NullableMatrix{T},
                         replacement::Any) # -> Matrix{T}
    return convert(Array{T, 2}, X, replacement)
end

function Base.convert{T, N}(::Type{Array},
                            X::NullableArray{T, N},
                            replacement::Any) # -> Array{T, N}
    return convert(Array{T, N}, X, replacement)
end

@doc """
`float(X::NullableArray)`

Return a copy of `X` in which each non-null entry is converted to a floating
point type. Note that this method will throw an error for arguments `X` whose
element type is not "isbits".
""" ->
function Base.float(X::NullableArray) # -> NullableArray{T, N}
    isbits(eltype(X)) || error()
    return NullableArray(float(X.values), copy(X.isnull))
end
