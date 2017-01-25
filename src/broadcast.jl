using Compat

if VERSION >= v"0.6.0-dev.693"
    using Base.Broadcast: check_broadcast_indices, broadcast_indices
else
    using Base.Broadcast: check_broadcast_shape, broadcast_shape
    const check_broadcast_indices = check_broadcast_shape
    const broadcast_indices = broadcast_shape
end

if VERSION < v"0.6.0-dev" # Old approach needed for inference to work
    using Base: _default_eltype

    ftype(f, A) = typeof(f)
    ftype(f, A...) = typeof(a -> f(a...))
    ftype(T::DataType, A) = Type{T}
    ftype(T::DataType, A...) = Type{T}

    if isdefined(Base, :Iterators)
        using Base.Iterators: Zip2
    else
        using Base: Zip2
    end
    ziptype(A) = Tuple{eltype(eltype(A))}
    ziptype(A, B) = Zip2{Tuple{eltype(eltype(A))}, Tuple{eltype(eltype(B))}}
    @inline ziptype(A, B, C, D...) = Zip{Tuple{eltype(A)}, ziptype(B, C, D...)}

    nullable_broadcast_eltype(f, As...) =
        _default_eltype(Base.Generator{ziptype(As...), ftype(f, As...)})
else
    Base.@pure nullable_eltypestuple(a) = Tuple{eltype(eltype(a))}
    Base.@pure nullable_eltypestuple(T::Type) = Tuple{Type{eltype(T)}}
    Base.@pure nullable_eltypestuple(a, b...) =
        Tuple{nullable_eltypestuple(a).types..., nullable_eltypestuple(b...).types...}

    Base.@pure function nullable_broadcast_eltype(f, As...)
        T = Core.Inference.return_type(f, nullable_eltypestuple(As...))
        T === Union{} ? Any : T
    end
end

invoke_broadcast!{F, N}(f::F, dest, As::Vararg{NullableArray, N}) =
    invoke(broadcast!, Tuple{F, AbstractArray, Vararg{AbstractArray, N}}, f, dest, As...)

"""
    broadcast(f, As::NullableArray...)

Call `broadcast` with nullable lifting semantics and return a `NullableArray`.
Lifting means calling function `f` on the the values wrapped inside `Nullable` entries
of the input arrays, and returning null if any entry is missing.

Note that this method's signature specifies the source `As` arrays as all
`NullableArray`s. Thus, calling `broadcast` on arguments consisting
of both `Array`s and `NullableArray`s will fall back to the standard implementation
of `broadcast` (i.e. without lifting).
"""
function Base.broadcast{F}(f::F, As::NullableArray...)
    # These definitions are needed to avoid allocation due to splatting
    @inline f2(x1) = lift(f, (x1,))
    @inline f2(x1, x2) = lift(f, (x1, x2))
    @inline f2(x1, x2, x3) = lift(f, (x1, x2, x3))
    @inline f2(x1, x2, x3, x4) = lift(f, (x1, x2, x3, x4))
    @inline f2(x1, x2, x3, x4, x5) = lift(f, (x1, x2, x3, x4, x5))
    @inline f2(x1, x2, x3, x4, x5, x6) = lift(f, (x1, x2, x3, x4, x5, x6))
    @inline f2(x1, x2, x3, x4, x5, x6, x7) = lift(f, (x1, x2, x3, x4, x5, x6, x7))
    @inline f2(x...) = lift(f, x)

    T = nullable_broadcast_eltype(f, As...)
    dest = similar(NullableArray{T}, broadcast_indices(As...))
    invoke_broadcast!(f2, dest, As...)
end

"""
    broadcast!(f, dest::NullableArray, As::NullableArray...)

Call `broadcast!` with nullable lifting semantics.
Lifting means calling function `f` on the the values wrapped inside `Nullable` entries
of the input arrays, and returning null if any entry is missing.

Note that this method's signature specifies the destination `dest` array as well as the
source `As` arrays as all `NullableArray`s. Thus, calling `broadcast!` on a arguments
consisting of both `Array`s and `NullableArray`s will fall back to the standard implementation
of `broadcast!` (i.e. without lifting).
"""
function Base.broadcast!{F}(f::F, dest::NullableArray, As::NullableArray...)
    # These definitions are needed to avoid allocation due to splatting
    @inline f2(x1) = lift(f, (x1,))
    @inline f2(x1, x2) = lift(f, (x1, x2))
    @inline f2(x1, x2, x3) = lift(f, (x1, x2, x3))
    @inline f2(x1, x2, x3, x4) = lift(f, (x1, x2, x3, x4))
    @inline f2(x1, x2, x3, x4, x5) = lift(f, (x1, x2, x3, x4, x5))
    @inline f2(x1, x2, x3, x4, x5, x6) = lift(f, (x1, x2, x3, x4, x5, x6))
    @inline f2(x1, x2, x3, x4, x5, x6, x7) = lift(f, (x1, x2, x3, x4, x5, x6, x7))
    @inline f2(x...) = lift(f, x)

    invoke_broadcast!(f2, dest, As...)
end

# To fix ambiguity
function Base.broadcast!{F}(f::F, dest::NullableArray)
    f2() = lift(f)
    invoke_broadcast!(f2, dest)
end

# broadcasted ops
if VERSION < v"0.6.0-dev.1632"
    for (op, scalar_op) in (
        (:(@compat Base.:(.==)), :(==)),
        (:(@compat Base.:.!=), :!=),
        (:(@compat Base.:.<), :<),
        (:(@compat Base.:.>), :>),
        (:(@compat Base.:.<=), :<=),
        (:(@compat Base.:.>=), :>=)
    )
        @eval begin
            ($op)(X::NullableArray, Y::NullableArray) = broadcast($scalar_op, X, Y)
        end
    end
end
