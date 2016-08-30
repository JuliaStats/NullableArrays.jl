## Lifted operators

importall Base.Operators
import Base: promote_op, abs, abs2, sqrt, cbrt, scalarmin, scalarmax, isless
using Compat: @functorize

# Methods adapted from Base Julia 0.5
if VERSION < v"0.5.0-dev+5096"
    promote_op(::Any, T) = T
    promote_op{T}(::Type{T}, ::Any) = T

    promote_op{R<:Number}(op, ::Type{R}) = typeof(op(one(R)))
    promote_op{R<:Number,S<:Number}(op, ::Type{R}, ::Type{S}) = typeof(op(one(R), one(S)))
end

"""
    null_safe_op(f::Any, ::Type)::Bool
    null_safe_op(f::Any, ::Type, ::Type)::Bool

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
null_safe_op(f::Any, ::Type) = false
null_safe_op(f::Any, ::Type, ::Type) = false

typealias SafeSignedInts Union{Int128,Int16,Int32,Int64,Int8}
typealias SafeUnsignedInts Union{Bool,UInt128,UInt16,UInt32,UInt64,UInt8}
typealias SafeInts  Union{SafeSignedInts,SafeUnsignedInts}
typealias SafeFloats Union{Float16,Float32,Float64}

# Float types appear in both since they promote to themselves,
# and therefore can't fail due to conversion of negative numbers
typealias SafeSigned Union{SafeSignedInts,SafeFloats}
typealias SafeUnsigned Union{SafeUnsignedInts,SafeFloats}
typealias SafeTypes Union{SafeInts,SafeFloats}

# Unary operators

# Note this list does not include sqrt since it can raise an error,
# nor cbrt (for which there is no functor on Julia 0.4)
for op in (:+, :-, :abs, :abs2)
    @eval begin
        null_safe_op{T<:SafeTypes}(::typeof(@functorize($op)), ::Type{T}) = true
    end
end

# No functors for these methods on 0.4: use the slow path
if VERSION >= v"0.5.0-dev"
    null_safe_op{T<:SafeInts}(::typeof(~), ::Type{T}) = true
    null_safe_op{T<:SafeTypes}(::typeof(cbrt), ::Type{T}) = true
    null_safe_op(::typeof(!), ::Type{Bool}) = true
end

for op in (:+, :-, :!, :~, :abs, :abs2, :sqrt, :cbrt)
    @eval begin
        @inline function $op{S}(x::Nullable{S})
            R = promote_op($op, S)
            if null_safe_op(@functorize($op), S)
                Nullable{R}($op(x.value), x.isnull)
            else
                x.isnull ? Nullable{R}() :
                           Nullable{R}($op(x.value))
            end
        end
        $op(x::Nullable{Union{}}) = Nullable()
    end
end

# Binary operators

# Note this list does not include ^, ÷ and %
# Operations between signed and unsigned types are not safe: promotion to unsigned
# gives an InexactError for negative numbers
if VERSION >= v"0.5.0-dev"
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
else # No functors for all methods on 0.4: use the slow path for missing ones
    for op in (:+, :-, :*, :/, :&, :|,
               :<, :>,
               :scalarmin, :scalarmax)
        @eval begin
            # to fix ambiguities
            null_safe_op{S<:SafeFloats,
                         T<:SafeFloats}(::typeof(@functorize($op)), ::Type{S}, ::Type{T}) = true
            null_safe_op{S<:SafeSigned,
                         T<:SafeSigned}(::typeof(@functorize($op)), ::Type{S}, ::Type{T}) = true
            null_safe_op{S<:SafeUnsigned,
                         T<:SafeUnsigned}(::typeof(@functorize($op)), ::Type{S}, ::Type{T}) = true
        end
    end
end

for op in (:+, :-, :*, :/, :%, :÷, :&, :|, :^, :<<, :>>, :(>>>),
           :(==), :<, :>, :<=, :>=,
           :scalarmin, :scalarmax)
    @eval begin
        @inline function $op{S,T}(x::Nullable{S}, y::Nullable{T})
            R = promote_op(@functorize($op), S, T)
            if null_safe_op(@functorize($op), S, T)
                Nullable{R}($op(x.value, y.value), x.isnull | y.isnull)
            else
                (x.isnull | y.isnull) ? Nullable{R}() :
                                        Nullable{R}($op(x.value, y.value))
            end
        end
        $op(x::Nullable{Union{}}, y::Nullable{Union{}}) = Nullable()
        $op{S}(x::Nullable{Union{}}, y::Nullable{S}) = Nullable{S}()
        $op{S}(x::Nullable{S}, y::Nullable{Union{}}) = Nullable{S}()
    end
end

if !method_exists(isless, (Nullable, Nullable))
    function isless{S,T}(x::Nullable{S}, y::Nullable{T})
        # NULL values are sorted last
        if null_safe_op(@functorize(isless), S, T)
            (!x.isnull & y.isnull) |
            (!x.isnull & !y.isnull & isless(x.value, y.value))
        else
            if x.isnull
                return false
            elseif y.isnull
                return true
            else
                return isless(x.value, y.value)
            end
        end
    end
    isless(x::Nullable{Union{}}, y::Nullable{Union{}}) = false
    isless(x::Nullable{Union{}}, y::Nullable) = false
    isless(x::Nullable, y::Nullable{Union{}}) = !x.isnull
end
