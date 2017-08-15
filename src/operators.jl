## Lifted operators

import Base: promote_op, scalarmin, scalarmax
using Compat

if isdefined(Base, :fieldname) && Base.fieldname(Nullable, 1) == :hasvalue # Julia 0.6
    _Nullable(R, x, hasvalue::Bool) = Nullable{R}(x, hasvalue)
else
    _Nullable(R, x, hasvalue::Bool) = Nullable{R}(x, !hasvalue)
end

"""
    null_safe_op(f::Any, ::Type...)::Bool

Returns whether an operation `f` can safely be applied to any value of the passed type(s).
Returns `false` by default.

Custom types should implement methods for some or all operations `f` when applicable:
returning `true` means that the operation may be called on any bit pattern without
throwing an error (though returning invalid or nonsensical results is not a problem).
In particular, this means that the operation can be applied on the whole domain of the
type *and on uninitialized objects*. As a general rule, these proporties are only true for
safe operations on `isbits` types.

Types declared as safe can benefit from higher performance for operations on nullable: by
always computing the result even for null values, a branch is avoided, which helps
vectorization.
"""
null_safe_op(f::Any, ::Type...) = false

@compat const SafeSignedInts = Union{Int128,Int16,Int32,Int64,Int8}
@compat const SafeUnsignedInts = Union{Bool,UInt128,UInt16,UInt32,UInt64,UInt8}
@compat const SafeInts = Union{SafeSignedInts,SafeUnsignedInts}
@compat const SafeFloats = Union{Float16,Float32,Float64}

# Float types appear in both since they promote to themselves,
# and therefore can't fail due to conversion of negative numbers
@compat const SafeSigned = Union{SafeSignedInts,SafeFloats}
@compat const SafeUnsigned = Union{SafeUnsignedInts,SafeFloats}
@compat const SafeTypes = Union{SafeInts,SafeFloats}

# Unary operators

# Note this list does not include sqrt since it can raise an error,
# nor cbrt (for which there is no functor on Julia 0.4)
for op in (:+, :-, :abs, :abs2)
    @eval begin
        null_safe_op{T<:SafeTypes}(::typeof($op), ::Type{T}) = true
    end
end

null_safe_op{T<:SafeInts}(::typeof(~), ::Type{T}) = true
null_safe_op{T<:SafeTypes}(::typeof(cbrt), ::Type{T}) = true
null_safe_op(::typeof(!), ::Type{Bool}) = true

# Temporary workaround until JuliaLang/julia#18803
null_safe_op(::typeof(cbrt), ::Type{Float16}) = false

for op in (:+, :-, :!, :~, :abs, :abs2, :sqrt, :cbrt)
    @eval begin
        @inline function Base.$op{S}(x::Nullable{S})
            R = promote_op($op, S)
            if null_safe_op($op, S)
                _Nullable(R, $op(x.value), !isnull(x))
            else
                isnull(x) ? Nullable{R}() :
                            Nullable{R}($op(x.value))
            end
        end
        Base.$op(x::Nullable{Union{}}) = Nullable()
    end
end

# Binary operators

# Note this list does not include ^, ÷ and %
# Operations between signed and unsigned types are not safe: promotion to unsigned
# gives an InexactError for negative numbers
for op in (:+, :-, :*, :/, :&, :|, :<<, :>>, :(>>>),
           :(==), :<, :>, :<=, :>=,
           :scalarmin, :scalarmax,
           :isless)
    @eval begin
        # to fix ambiguities
        null_safe_op{S<:SafeFloats,
                     T<:SafeFloats}(::typeof($op), ::Type{S}, ::Type{T}) = true
        null_safe_op{S<:SafeSigned,
                     T<:SafeSigned}(::typeof($op), ::Type{S}, ::Type{T}) = true
        null_safe_op{S<:SafeUnsigned,
                     T<:SafeUnsigned}(::typeof($op), ::Type{S}, ::Type{T}) = true
    end
end

for op in (:+, :-, :*, :/, :%, :÷, :&, :|, :^, :<<, :>>, :(>>>),
           :(==), :<, :>, :<=, :>=,
           :scalarmin, :scalarmax)
    @eval begin
        @inline function Base.$op{S,T}(x::Nullable{S}, y::Nullable{T})
            R = promote_op(Base.$op, S, T)
            if null_safe_op(Base.$op, S, T)
                _Nullable(R, Base.$op(x.value, y.value), !(isnull(x) | isnull(y)))
            else
                (isnull(x) | isnull(y)) ? Nullable{R}() :
                                          Nullable{R}(Base.$op(x.value, y.value))
            end
        end
        Base.$op(x::Nullable{Union{}}, y::Nullable{Union{}}) = Nullable()
        Base.$op{S}(x::Nullable{Union{}}, y::Nullable{S}) = Nullable{S}()
        Base.$op{S}(x::Nullable{S}, y::Nullable{Union{}}) = Nullable{S}()
    end
end

if !method_exists(isless, Tuple{Nullable{Int}, Nullable{Int}})
    function Base.isless{S,T}(x::Nullable{S}, y::Nullable{T})
        # NULL values are sorted last
        if null_safe_op(isless, S, T)
            (!isnull(x) & isnull(y)) |
            (!isnull(x) & !isnull(y) & isless(x.value, y.value))
        else
            if isnull(x)
                return false
            elseif isnull(y)
                return true
            else
                return isless(x.value, y.value)
            end
        end
    end
    Base.isless(x::Nullable{Union{}}, y::Nullable{Union{}}) = false
    Base.isless(x::Nullable{Union{}}, y::Nullable) = false
    Base.isless(x::Nullable, y::Nullable{Union{}}) = !isnull(x)
end
