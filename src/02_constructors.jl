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
function NullableArray{T}(::Type{T}, dims::Dims)
    NullableArray(
        fill(true, dims),
        Array(T, dims),
    )
end
