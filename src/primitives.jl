@inline Base.isnull(X::NullableArray, I::Int...) = X.isnull[I...]
@inline Base.isnull{T}(X::AbstractArray{Nullable{T}}, I::Int...) = isnull(X[I...]) # fallback method
@inline Base.values(X::NullableArray, I::Int...) = X.values[I...]

"""
    size(X::NullableArray, [d::Real])

Return a tuple containing the lengths of each dimension of `X`, or if `d` is
specific, the length of `X` along dimension `d`.
"""
Base.size(X::NullableArray) = size(X.values) # -> NTuple{Int}

"""
    similar(X::NullableArray, [T], [dims])

Allocate an uninitialized `NullableArray` of element type `T` and with
size `dims`. If unspecified, `T` and `dims` default to the element type and size
equal to that of `X`.
"""
function Base.similar{T}(X::NullableArray, ::Type{T}, dims::Dims)
    T<:Nullable ? NullableArray(eltype(T), dims) : NullableArray(T, dims)
end

"""
    copy(X::NullableArray)

Return a shallow copy of `X`; the outer structure of `X` will be copied, but
all elements will be identical to those of `X`.
"""
Base.copy{T}(X::NullableArray{T}) = Base.copy!(similar(X, T), X)

"""
    copy!(dest::NullableArray, src::NullableArray)

Copy the initialized values of a source NullableArray into the respective
indices of the destination NullableArray. If an entry in `src` is null, then
this method nullifies the respective entry in `dest`.
"""
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

"""
    fill!(X::NullableArray, x::Nullable)

Fill `X` with the value `x`. If `x` is empty, then `fill!(X, x)` nullifies each
entry of `X`. Otherwise, `fill!(X, x)` fills `X.values` with the value of `x`
and designates each entry of `X` as present.
"""
function Base.fill!(X::NullableArray, x::Nullable) # -> NullableArray{T, N}
    if isnull(x)
        fill!(X.isnull, true)
    else
        fill!(X.values, get(x))
        fill!(X.isnull, false)
    end
    return X
end

"""
    fill!(X::NullableArray, x::Nullable)

Fill `X` with the value `x` and designate each entry as present. If `x` is an
object reference, all elements will refer to the same object. Note that
`fill!(X, Foo())` will return `X` filled with the result of evaluating `Foo()`
once.
"""
function Base.fill!(X::NullableArray, x::Any) # -> NullableArray{T, N}
    fill!(X.values, x)
    fill!(X.isnull, false)
    return X
end

"""
    Base.deepcopy(X::NullableArray)

Return a `NullableArray` object whose internal `values` and `isnull` fields are
deep copies of `X.values` and `X.isnull` respectively.
"""
function Base.deepcopy(X::NullableArray) # -> NullableArray{T}
    return NullableArray(deepcopy(X.values), deepcopy(X.isnull))
end

"""
    resize!(X::NullableVector, n::Int)

Resize a one-dimensional `NullableArray` `X` to contain precisely `n` elements.
If `n` is greater than the current length of `X`, then each new entry will be
designated as null.
"""
function Base.resize!{T}(X::NullableArray{T,1}, n::Int) # -> NullableArray{T, 1}
    resize!(X.values, n)
    oldn = length(X.isnull)
    resize!(X.isnull, n)
    X.isnull[oldn+1:n] = true
    return X
end

function Base.reshape(X::NullableArray, dims::Dims) # -> NullableArray
    NullableArray(reshape(X.values, dims), reshape(X.isnull, dims))
end

"""
    ndims(X::NullableArray)

Returns the number of dimensions of `X`.
"""
Base.ndims(X::NullableArray) = ndims(X.values) # -> Int

"""
    length(X::NullableArray)

Returns the maximum index `i` for which `getindex(X, i)` is valid.
"""
Base.length(X::NullableArray) = length(X.values) # -> Int

"""
    endof(X::NullableArray)

Returns the last entry of `X`.
"""
Base.endof(X::NullableArray) = endof(X.values) # -> Int

function Base.find(X::NullableArray{Bool}) # -> Array{Int}
    ntrue = 0
    @inbounds for (i, isnull) in enumerate(X.isnull)
        ntrue += !isnull && X.values[i]
    end
    res = Array{Int}(ntrue)
    ind = 1
    @inbounds for (i, isnull) in enumerate(X.isnull)
        if !isnull && X.values[i]
            res[ind] = i
            ind += 1
        end
    end
    return res
end


_isnull(x::Any) = false
_isnull(x::Nullable) = isnull(x)

"""
    dropnull(X::AbstractVector)

Return a vector containing only the non-null entries of `X`,
unwrapping `Nullable` entries. A copy is always returned, even when
`X` does not contain any null values.
"""
function dropnull{T}(X::AbstractVector{T})                  # -> AbstractVector
    if !(Nullable <: T) && !(T <: Nullable)
        return copy(X)
    else
        Y = filter(x->!_isnull(x), X)
        res = similar(Y, eltype(T))
        for i in eachindex(Y, res)
            @inbounds res[i] = isa(Y[i], Nullable) ? Y[i].value : Y[i]
        end
        return res
    end
end
dropnull(X::NullableVector) = X.values[(!).(X.isnull)]      # -> Vector

"""
    dropnull!(X::AbstractVector)

Remove null entries of `X` in-place and return a `Vector` view of the
unwrapped `Nullable` entries. If no nulls are present, this is a no-op
and `X` is returned.
"""
function dropnull!{T}(X::AbstractVector{T})                 # -> AbstractVector
    if !(Nullable <: T) && !(T <: Nullable)
        return X
    else
        deleteat!(X, find(isnull, X))
        res = similar(X, eltype(T))
        for i in eachindex(X, res)
            @inbounds res[i] = isa(X[i], Nullable) ? X[i].value : X[i]
        end
        return res
    end
end

"""
    dropnull!(X::NullableVector)

Remove null entries of `X` in-place and return a `Vector` view of the
unwrapped `Nullable` entries.
"""
# TODO: replace `find(X.isnull)` with `X.isnull` when
# https://github.com/JuliaLang/julia/pull/20465 is merged and part of
# current release (either v0.6 or v1.0)
dropnull!(X::NullableVector) = deleteat!(X, find(X.isnull)).values # -> Vector

"""
    isnan(X::NullableArray)

Test whether each entry of `X` is null and if not, test whether the entry is
not a number (`NaN`). Return the results as `NullableArray{Bool}`. Note that
null entries of `X` will be reflected by null entries of the resultant
`NullableArray`.
"""
function Base.isnan(X::NullableArray) # -> NullableArray{Bool}
    return NullableArray(@compat(isnan.(X.values)), copy(X.isnull))
end

"""
    isfinite(X::NullableArray)

Test whether each entry of `X` is null and if not, test whether the entry is
finite. Return the results as `NullableArray{Bool}`. Note that
null entries of `X` will be reflected by null entries of the resultant
`NullableArray`.
"""
function Base.isfinite(X::NullableArray) # -> NullableArray{Bool}
    res = Array{Bool}(size(X))
    for i in eachindex(X)
        if !X.isnull[i]
            res[i] = isfinite(X.values[i])
        end
    end
    return NullableArray(res, copy(X.isnull))
end

"""
    convert(T, X::NullableArray)

Convert `X` to an `AbstractArray` of type `T`. Note that if `X` contains any
null entries then calling `convert` without supplying a replacement value for
null entries will result in an error.

Currently supported return type arguments include: `Array`, `Array{T}`,
`Vector`, `Matrix`.

    convert(T, X::NullableArray, replacement)

Convert `X` to an `AbstractArray` of type `T` and replace all null entries of
`X` with `replacement` in the result.
"""
function Base.convert{S, T, N}(::Type{Array{S, N}},
                               X::NullableArray{T, N}) # -> Array{S, N}
    if any(isnull, X)
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
    res = Array{S}(size(X))
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

"""
    float(X::NullableArray)

Return a copy of `X` in which each non-null entry is converted to a floating
point type. Note that this method will throw an error for arguments `X` whose
element type is not "isbits".
"""
function Base.float(X::NullableArray) # -> NullableArray{T, N}
    isbits(eltype(X)) || error()
    return NullableArray(float(X.values), copy(X.isnull))
end

Base.any(::typeof(isnull), X::NullableArray) = Base.any(X.isnull)
Base.all(::typeof(isnull), X::NullableArray) = Base.all(X.isnull)
