@doc """
`NullableArray{T, N}` is an efficient alternative to `Array{Nullable{T}, N}`.
It allows users to define operations on arrays with null values by reusing
operations that only work on arrays without any null values. We refer to
such reuse as "lifting" an operation from the domain of non-nullable values
to the domain of nullable values. Examples include lifting the definition of
matrix multiplication from non-nullable arrays to nullable arrays.
""" ->
immutable NullableArray{T, N} <: AbstractArray{Nullable{T}, N}
    values::Array{T, N}
    isnull::Array{Bool, N}

    function NullableArray(d::AbstractArray{T, N}, m::Array{Bool, N})
        if size(d) != size(m)
            msg = "values and missingness arrays must be the same size"
            throw(ArgumentError(msg))
        end
        new(d, m)
    end
end

@doc """
`NullableVector{T}` is an alias for `NullableArray{T, 1}`
""" ->
typealias NullableVector{T} NullableArray{T, 1}

@doc """
`NullableMatrix{T}` is an alias for `NullableArray{T, 2}`
""" ->
typealias NullableMatrix{T} NullableArray{T, 2}
