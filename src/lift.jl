
eltype_nullable(x::Nullable) = eltype(x)
eltype_nullable(x) = typeof(x)
eltype_nullable{T<:Nullable}(::Type{T}) = eltype(T)
eltype_nullable{T}(::Type{T}) = T

if VERSION >= v"0.6.0-dev"
    @inline function lift{F}(f::F, x)
        if null_safe_op(f, eltype_nullable(x))
            return @compat Nullable(f(unsafe_get(x)), !isnull(x))
        else
            U = Core.Inference.return_type(f, Tuple{eltype(x)})
            if isnull(x)
                return isleaftype(U) ? Nullable{U}() : Nullable()
            else
                return Nullable(f(unsafe_get(x)))
            end
        end
    end

    @inline function lift{F}(f::F, x1, x2)
        if null_safe_op(f, eltype_nullable(x1), eltype_nullable(x2))
            return @compat Nullable(f(unsafe_get(x1), unsafe_get(x2)),
                                    !(isnull(x1) | isnull(x2)))
        else
            U = Core.Inference.return_type(f, Tuple{eltype(x1), eltype(x2)})
            if isnull(x1) | isnull(x2)
                return isleaftype(U) ? Nullable{U}() : Nullable()
            else
                return Nullable(f(unsafe_get(x1), unsafe_get(x2)))
            end
        end
    end
end

eltypes() = Tuple{}
eltypes(x) = Tuple{eltype_nullable(x)}
eltypes(x, xs...) = Tuple{eltype_nullable(x), eltypes(xs...).parameters...}

"""
  lift(f, xs...)

Lift function `f`, passing it arguments `xs...`, using standard lifting semantics:
for a function call `f(xs...)`, return null if any `x` in `xs` is null; otherwise,
return `f` applied to values of `xs`.
"""
@generated function lift{F, T, N}(f::F, xs::Vararg{T, N})
    args = (:(unsafe_get(xs[$i])) for i in 1:N)
    checknull = (:(isnull(xs[$i])) for i in 1:N)
    if null_safe_op(f.instance, eltypes(xs...).parameters...)
        return quote
            @Base._inline_meta
            @inbounds val = f($(args...))
            @inbounds hasnulls = |($(checknull...))
            @compat Nullable(val, !hasnulls)
        end
    else
      return quote
          @Base._inline_meta
          U = Core.Inference.return_type(f, eltypes(xs...))
          @inbounds hasnulls = |($(checknull...))
          if hasnulls
              return isleaftype(U) ? Nullable{U}() : Nullable()
          else
              @inbounds val = f($(args...))
              return Nullable(val)
          end
      end
    end
end

lift(f) = Nullable(f())
