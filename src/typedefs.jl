using Compat

# === Design Notes ===
#
# `NullableArray{T, N}` is a struct-of-arrays representation of
# `Array{Nullable{T}, N}`. This makes it easy to define complicated operations
# (e.g. matrix multiplication) by reusing the existing definition for
# `Array{T}`.
#
# One complication when defining functions that operate on the internal fields
# of a `NullableArray` is that developers must take care to ensure that they
# do not index into an undefined entry in the `values` field. This is not a
# problem for `isbits` types, which are never `#undef`, but will trigger
# an exception for any other type.
#
# TODO: Ensure that size(values) == size(isnull) using inner constructor.
if VERSION >= v"0.6.0-dev.2643"
    include_string("""
        immutable NullableArray{T, N} <: AbstractArray{Nullable{T}, N}
            values::Array{T, N}
            isnull::Array{Bool, N}
            # extra field for potentially holding a reference to a parent memory block
            # (think mmapped file, for example) that `values` is actually derived from
            parent::Vector{UInt8}

            function NullableArray{T, N}(d::AbstractArray{T, N},
                                         m::AbstractArray{Bool, N},
                                         parent::Vector{UInt8}=Vector{UInt8}()) where {T, N}
                if size(d) != size(m)
                    msg = "values and missingness arrays must be the same size"
                    throw(ArgumentError(msg))
                end
                new(d, m, parent)
            end
        end
    """)
else
    immutable NullableArray{T, N} <: AbstractArray{Nullable{T}, N}
        values::Array{T, N}
        isnull::Array{Bool, N}
        # extra field for potentially holding a reference to a parent memory block
        # (think mmapped file, for example) that `values` is actually derived from
        parent::Vector{UInt8}

        function NullableArray(d::AbstractArray{T, N}, m::AbstractArray{Bool, N}, parent::Vector{UInt8}=Vector{UInt8}())
            if size(d) != size(m)
                msg = "values and missingness arrays must be the same size"
                throw(ArgumentError(msg))
            end
            new(d, m, parent)
        end
    end
end

"""
`NullableArray{T, N}` is an efficient alternative to `Array{Nullable{T}, N}`.
It allows users to easily define operations on arrays with null values by
reusing operations that only work on arrays without any null values.
"""
NullableArray

@compat NullableVector{T} = NullableArray{T, 1}
@compat NullableMatrix{T} = NullableArray{T, 2}
