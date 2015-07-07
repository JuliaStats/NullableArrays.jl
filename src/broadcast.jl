#----- broadcasted binary operations -----------------------------------------#

# The following require specialized implementations because the base/broadcast
# methods return BitArrays instead of similars of the arguments.
# An alternative to the following implementations is simply to let the base
# implementations use convert(::Type{Bool}, ::Nullable{Bool}), but this is
# slower.
for (op, scalar_op) in (
    (:.==, :(==)),
    (:.!=, :!=),
    (:.<, :<),
    (:.>, :>),
    (:.<=, :<=),
    (:.>=, :>=)
)
    @eval begin
        ($op)(X::NullableArray, Y::NullableArray) = broadcast($scalar_op, X, Y)
    end
end
