## Lifted operators

importall Base.Operators
import Base: abs,
             abs2,
             cbrt,
             isless,
             scalarmin,
             scalarmax,
             promote_op,
             promote_rule,
             sqrt,
             typed_hcat,
             typed_vcat
using Compat: @compat, @functorize

if isdefined(Base, :fieldname) && Base.fieldname(Nullable, 1) == :hasvalue # Julia 0.6
    _Nullable(R, x, hasvalue::Bool) = Nullable{R}(x, hasvalue)
else
    _Nullable(R, x, hasvalue::Bool) = Nullable{R}(x, !hasvalue)
end

# Methods adapted from Base Julia 0.5
if VERSION < v"0.5.0-dev+5096"
    promote_op(::Any, T) = T
    promote_op{T}(::Type{T}, ::Any) = T

    promote_op{R<:Number}(op, ::Type{R}) = typeof(op(one(R)))
    promote_op{R<:Number,S<:Number}(op, ::Type{R}, ::Type{S}) = typeof(op(one(R), one(S)))
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
        null_safe_op{T<:SafeTypes}(::typeof(@functorize($op)), ::Type{T}) = true
    end
end

# No functors for these methods on 0.4: use the slow path
if VERSION >= v"0.5.0-dev"
    null_safe_op{T<:SafeInts}(::typeof(~), ::Type{T}) = true
    null_safe_op{T<:SafeTypes}(::typeof(cbrt), ::Type{T}) = true
    null_safe_op(::typeof(!), ::Type{Bool}) = true

    # Temporary workaround until JuliaLang/julia#18803
    null_safe_op(::typeof(cbrt), ::Type{Float16}) = false
end

for op in (:+, :-, :!, :~, :abs, :abs2, :sqrt, :cbrt)
    @eval begin
        @inline function $op{S}(x::Nullable{S})
            R = promote_op($op, S)
            if null_safe_op(@functorize($op), S)
                _Nullable(R, $op(x.value), !isnull(x))
            else
                isnull(x) ? Nullable{R}() :
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
                _Nullable(R, $op(x.value, y.value), !(isnull(x) | isnull(y)))
            else
                (isnull(x) | isnull(y)) ? Nullable{R}() :
                                          Nullable{R}($op(x.value, y.value))
            end
        end
        $op(x::Nullable{Union{}}, y::Nullable{Union{}}) = Nullable()
        $op{S}(x::Nullable{Union{}}, y::Nullable{S}) = Nullable{S}()
        $op{S}(x::Nullable{S}, y::Nullable{Union{}}) = Nullable{S}()
    end
end

if !method_exists(isless, Tuple{Nullable{Int}, Nullable{Int}})
    function isless{S,T}(x::Nullable{S}, y::Nullable{T})
        # NULL values are sorted last
        if null_safe_op(@functorize(isless), S, T)
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
    isless(x::Nullable{Union{}}, y::Nullable{Union{}}) = false
    isless(x::Nullable{Union{}}, y::Nullable) = false
    isless(x::Nullable, y::Nullable{Union{}}) = !isnull(x)
end

function promote_rule{T1,T2}(::Type{T1}, ::Type{Nullable{T2}})
    promote_rule(Nullable{T2}, T1)
end

function typed_hcat{T}(::Type{T}, A::AbstractVecOrMat...)
    nargs = length(A)
    nrows = size(A[1], 1)
    ncols = 0
    dense = true
    for j = 1:nargs
        Aj = A[j]
        if size(Aj, 1) != nrows
            throw(ArgumentError("number of rows of each array must match (got $(map(x->size(x,1), A)))"))
        end
        dense &= isa(Aj,Array)
        nd = ndims(Aj)
        ncols += (nd==2 ? size(Aj,2) : 1)
    end
    i = findfirst(a -> isa(a, NullableArray), A)
    B = similar(full(A[i == 0 ? 1 : i]), T, nrows, ncols)
    pos = 1
    if dense
        for k=1:nargs
            Ak = A[k]
            n = length(Ak)
            copy!(B, pos, Ak, 1, n)
            pos += n
        end
    else
        for k=1:nargs
            Ak = A[k]
            p1 = pos+(isa(Ak,AbstractMatrix) ? size(Ak, 2) : 1)-1
            B[:, pos:p1] = Ak
            pos = p1+1
        end
    end
    return B
end

function typed_vcat{T}(::Type{T}, V::AbstractVector...)
    n::Int = 0
    for Vk in V
        n += length(Vk)
    end
    i = findfirst(v -> isa(v, NullableArray), V)
    a = similar(full(V[i == 0 ? 1 : i]), T, n)
    pos = 1
    for k=1:length(V)
        Vk = V[k]
        p1 = pos+length(Vk)-1
        a[pos:p1] = Vk
        pos = p1+1
    end
    a
end

function typed_vcat{T}(::Type{T}, A::AbstractMatrix...)
    nargs = length(A)
    nrows = sum(a->size(a, 1), A)::Int
    ncols = size(A[1], 2)
    for j = 2:nargs
        if size(A[j], 2) != ncols
            throw(ArgumentError("number of columns of each array must match (got $(map(x->size(x,2), A)))"))
        end
    end
    i = findfirst(a -> isa(a, NullableArray), A)
    B = similar(full(A[i == 0 ? 1 : i]), T, nrows, ncols)
    pos = 1
    for k=1:nargs
        Ak = A[k]
        p1 = pos+size(Ak,1)-1
        B[pos:p1, :] = Ak
        pos = p1+1
    end
    return B
end
