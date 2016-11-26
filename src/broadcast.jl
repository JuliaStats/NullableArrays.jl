using Base: _default_eltype
using Compat

if VERSION >= v"0.6.0-dev.693"
    using Base.Broadcast: check_broadcast_indices, broadcast_indices
else
    using Base.Broadcast: check_broadcast_shape, broadcast_shape
    const check_broadcast_indices = check_broadcast_shape
    const broadcast_indices = broadcast_shape
end

if !isdefined(Base.Broadcast, :ftype) # Julia < 0.6
    ftype(f, A) = typeof(f)
    ftype(f, A...) = typeof(a -> f(a...))
    ftype(T::DataType, A) = Type{T}
    ftype(T::DataType, A...) = Type{T}
else
    using Base.Broadcast: ftype
end

if !isdefined(Base.Broadcast, :ziptype) # Julia < 0.6
    if isdefined(Base, :Iterators)
        using Base.Iterators: Zip2
    else
        using Base: Zip2
    end
    ziptype(A) = Tuple{eltype(A)}
    ziptype(A, B) = Zip2{Tuple{eltype(A)}, Tuple{eltype(B)}}
    @inline ziptype(A, B, C, D...) = Zip{Tuple{eltype(A)}, ziptype(B, C, D...)}
else
    using Base.Broadcast: ziptype
end

@inline @generated function broadcast_lift{F, T}(f::F, x::NTuple{1, T})
    if null_safe_op(f.instance, eltype(T))
        return :( Nullable(f(unsafe_get(x[1])), !isnull(x[1])) )
    else
        U = Core.Inference.return_type(f.instance, Tuple{eltype(T)})
        return quote
            if isnull(x)
                return Nullable{$U}()
            else
                return Nullable(f(unsafe_get(x[1])))
            end
        end
    end
end

@inline @generated function broadcast_lift{F, S, T}(f::F, x::Tuple{S, T})
    if null_safe_op(f.instance, eltype(S), eltype(T))
        return :( Nullable(f(unsafe_get(x[1]), unsafe_get(x[2])),
                           !(isnull(x[1]) | isnull(x[2]))) )
    else
        U = Core.Inference.return_type(f.instance, Tuple{eltype(S), eltype(T)})
        return quote
            if isnull(x[1]) | isnull(x[2])
                return Nullable{$U}()
            else
                return Nullable(f(unsafe_get(x[1]), unsafe_get(x[2])))
            end
        end
    end
end

eltypes() = Tuple{}
eltypes(x) = Tuple{eltype(x)}
eltypes(x, xs...) = Tuple{eltype(x), eltypes(xs...).parameters...}

"""
  broadcast_lift(f, x)

Lift function `f`, passing it arguments from the tuple `x`, using standard lifting semantics:
for a function call `f(x...)`, return null if any `x` in `x` is null; otherwise,
return `f` applied to values of `x`.
"""
@inline @generated function broadcast_lift{F}(f::F, x::Tuple)
    if null_safe_op(f.instance, eltypes(x).parameters...)
        # TODO: find a more efficient approach than mapreduce
        # (i.e. one which gets lowered to just isnull(x1) | isnull(x2) | ...)
        return :( Nullable(f(unsafe_get.(x)), !mapreduce(isnull, |, x)) )
    else
        U = Core.Inference.return_type(f.instance, eltypes(x))
        return quote
            # TODO: find a more efficient approach than mapreduce
            # (i.e. one which gets lowered to just isnull(x1) | isnull(x2) | ...)
            if mapreduce(isnull, |, x)
                return Nullable{$U}()
            else
                return Nullable(f(map(unsafe_get, x)...))
            end
        end
    end
end

call_broadcast{F, N}(f::F, dest, As::Vararg{NullableArray, N}) =
    invoke(broadcast!, Tuple{Function, AbstractArray, Vararg{AbstractArray, N}}, f, dest, As...)

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
function Base.broadcast{F, N}(f::F, As::Vararg{NullableArray, N})
    # These definitions are needed to avoid allocation due to splatting
    f2(x1) = broadcast_lift(f, (x1,))
    f2(x1, x2) = broadcast_lift(f, (x1, x2))
    f2(x...) = broadcast_lift(f, x)

    T = _default_eltype(Base.Generator{ziptype(As...), ftype(f2, As...)})
    if isleaftype(T) && !(T <: Nullable)
        dest = similar(Array{eltype(T)}, broadcast_indices(As...))
    else
        dest = similar(NullableArray{eltype(T)}, broadcast_indices(As...))
    end
    call_broadcast(f2, dest, As...)
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
function Base.broadcast!{F, N}(f::F, dest::NullableArray, As::Vararg{NullableArray, N})
    # These definitions are needed to avoid allocation due to splatting
    f2(x1) = broadcast_lift(f, (x1,))
    f2(x1, x2) = broadcast_lift(f, (x1, x2))
    f2(x...) = broadcast_lift(f, x)
    call_broadcast(f2, dest, As...)
end

# To fix ambiguity
function Base.broadcast!{F}(f::F, dest::NullableArray)
    f2() = broadcast_lift(f, ())
    call_broadcast(f2, dest)
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
