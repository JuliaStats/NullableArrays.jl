eltype_nullable(x::Nullable) = eltype(x)
eltype_nullable(x) = typeof(x)
eltype_nullable{T<:Nullable}(::Type{T}) = eltype(T)
eltype_nullable{T}(::Type{T}) = T

eltypes(x) = Tuple{eltype_nullable(x)}
eltypes(x, xs...) = Tuple{eltype_nullable(x), eltypes(xs...).parameters...}

"""
  lift(f, xs...)

Lift function `f`, passing it arguments `xs...`, using standard lifting semantics:
for a function call `f(xs...)`, return null if any `x` in `xs` is null; otherwise,
return `f` applied to values of `xs`.
"""
@inline @generated function lift{F}(f::F, xs::Tuple)
    N = nfields(xs)
    args = (:(unsafe_get(xs[$i])) for i in 1:N)
    checknull = (:(!isnull(xs[$i])) for i in 1:N)
    if null_safe_op(f.instance, map(eltype_nullable, xs.parameters)...)
        return quote
            val = f($(args...))
            nonull = (&)($(checknull...))
            @compat Nullable(val, nonull)
        end
    else
      return quote
          U = Core.Inference.return_type(f, eltypes(xs...))
          if (&)($(checknull...))
              return Nullable(f($(args...)))
          else
              return isleaftype(U) ? Nullable{U}() : Nullable()
          end
      end
    end
end

lift(f) = Nullable(f())
