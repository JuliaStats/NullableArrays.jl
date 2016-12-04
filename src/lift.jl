@inline function lift(f, x)
    if null_safe_op(f, eltype(x))
        return @compat Nullable(f(unsafe_get(x)), !isnull(x))
    else
        U = Core.Inference.return_type(f, Tuple{eltype(x)})
        if isnull(x)
            return Nullable{U}()
        else
            return Nullable(f(unsafe_get(x)))
        end
    end
end

@inline function lift(f, x1, x2)
    if null_safe_op(f, eltype(x1), eltype(x2))
        return @compat Nullable(f(unsafe_get(x1), unsafe_get(x2)),
                                !(isnull(x1) | isnull(x2)))
    else
        U = Core.Inference.return_type(f, Tuple{eltype(x1), eltype(x2)})
        if isnull(x1) | isnull(x2)
            return Nullable{U}()
        else
            return Nullable(f(unsafe_get(x1), unsafe_get(x2)))
        end
    end
end

eltype_nullable(x::Nullable) = eltype(x)
eltype_nullable(x) = typeof(x)

eltypes() = Tuple{}
eltypes(x) = Tuple{eltype_nullable(x)}
eltypes(x, xs...) = Tuple{eltype_nullable(x), eltypes(xs...).parameters...}

hasnulls() = false
hasnulls(x) = isnull(x)
hasnulls(x, xs...) = hasnulls(x) | hasnulls(xs...)

_unsafe_get() = ()
_unsafe_get(x) = (unsafe_get(x),)
_unsafe_get(x, xs...) = (unsafe_get(x), _unsafe_get(xs...)...)

"""
  lift(f, xs...)

Lift function `f`, passing it arguments `xs...`, using standard lifting semantics:
for a function call `f(xs...)`, return null if any `x` in `xs` is null; otherwise,
return `f` applied to values of `xs`.
"""
@inline function lift(f, xs...)
    if null_safe_op(f, map(eltype_nullable, xs)...)
        return @compat Nullable(f(_unsafe_get(xs...)...), !hasnulls(xs...))
    else
        U = Core.Inference.return_type(f, eltypes(xs...))
        if hasnulls(xs...)
            return Nullable{U}()
        else
            return Nullable(f(_unsafe_get(xs...)...))
        end
    end
end
