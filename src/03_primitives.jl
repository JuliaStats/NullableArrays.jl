# We determine the size of a NullableArray array using the size of its
# `values` field. We could equivalently use the `.isnull` field.
Base.size(X::NullableArray) = size(X.values)

# Allocate a similar array
function Base.similar{T <: Nullable}(X::NullableArray, ::Type{T}, dims::Dims)
    NullableArray(eltype(T), dims)
end

# Allocate a similar array
Base.similar(X::NullableArray, T, dims::Dims) = NullableArray(T, dims)

# ----- Base.copy/copy! ------------------------------------------------------#

Base.copy(X::NullableArray) = Base.copy!(similar(X), X)


# Copies the initialized values of a source NullableArray into the respective
# indices of the destination NullableArray.
function Base.copy!(dest::NullableArray, src::NullableArray) # -> NullableArray
    if isbits(eltype(dest)) && isbits(eltype(src))
        copy!(dest.values, src.values)
    else
        dest_values = dest.values
        src_values = src_values
        length(dest_values) >= length(src_values) || throw(BoundsError())
        # Copy only initilialized values from src into dest
        # TODO: investigate "BoolArray.chunks"
        for i in 1:length(src_values)
            @inbounds !(src.isnull[i]) && (dest.values[i] = src.values[i])
        end
    end
    copy!(dest.isnull, src.isnull)
end

# ----- Base.fill! -----------------------------------------------------------#

function Base.fill!(A::NullableArray, x::Nullable)
    if isnull(x)
        fill!(A.isnull, true)
    else
        fill!(A.values, get(x))
        fill!(A.isnull, false)
    end
    return A
end

function Base.fill!(A::NullableArray, x::Any)
    fill!(A.values, x)
    fill!(A.isnull, false)
    return A
end

# ----- Base.deepcopy ------------

function Base.deepcopy(d::NullableArray) # -> NullableArray{T}
    return NullableArray(deepcopy(d.values), deepcopy(d.isnull))
end

# ----- Base.size



# ----- Base.resize!


# ----- Base.ndims


# ----- Base.length


# ----- Base.endof


# ----- Base.find


# ----- dropnull


# ----- isnull


# ----- anynull


# ----- allnull


# ----- Base.isnan


# ----- Base.isfinite


# ----- Base.convert


# ----- Base.promote


# ----- Base.hash


# ----- finduniques


# ----- Base.unique


# ----- levels
