module FunctionalNullableOperations

# extends Base with operations that treat nullables as collections

importall Base
import Base: promote_op, LinearFast

# conceptually, nullable types can be considered infinite-order tensor powers of
# finite-dimensional vector spaces — we attempt to support most operations on
# arrays except the linear algebra related ones; the infinite-dimensional nature
# makes subtyping AbstractArray a little dangerous, which explains why
# functionality is reimplemented instead of subtyping AbstractArray

# size   – not implemented since an infinite-dimensional tuple would be strange
# length – one or zero
# endof  – same as length
length(u::Nullable) = u.isnull ? 0 : 1
endof(u::Nullable)  = length(u)

# indexing is either without index, or with 1 as index
# generalized linear indexing is not supported
# setindex! not supported because Nullable is immutable
linearindexing{T}(::Nullable{T}) = LinearFast()
function getindex(u::Nullable)
    @boundscheck u.isnull && throw(NullException())
    u.value
end
function getindex(u::Nullable, i::Integer)
    @boundscheck u.isnull | (i ≠ one(i)) && throw(BoundsError(i, u))
    u.value
end

# iteration protocol
start(u::Nullable) = 1
next(u::Nullable, i::Integer) = u.value, 0
done(u::Nullable, i::Integer) = u.isnull || i == 0

# next we have reimplementations of some higher-order functions
filter{T}(p, u::Nullable{T}) = u.isnull ? u : p(u.value) ? u : Nullable{T}()

# warning: not type-stable
map{T}(f, u::Nullable{T}) = u.isnull ? Nullable{Union{}}() : Nullable(f(u.value))

# multi-argument map doesn't broadcast, so not very useful, but no harm having
# it...
function map(f, us::Nullable...)
    if all(isnull, us)
        Nullable()
    elseif !any(isnull, us)
        Nullable(map(f, map(getindex, us)...))
    else
        throw(DimensionMismatch("expected all null or all nonnull"))
    end
end

# foldr and foldl are quite useful to express "do something if not null, else"
# these

# being infinite-dimensional, nullables are generally incompatible with
# broadcast with arrays — it is probably not worth supporting the rare case
# where an array has length 0 or 1

# so we reimplement broadcast, which has the same semantics but very different
# implementation. This implementation is in fact much simpler than that for
# arrays. Length-1 (non-nulls) are flexible and can broadcast to length-0
# (nulls), but the other way does not work. Numbers are zero-dimensional and can
# broadcast to infinite-dimensional nullables, but the other direction is not
# supported.

# there are two shapes we are concerned about: infinite-dimensional 1×1×...
# and infinite-dimensional 0×0×...; we don't care about zero-dimensional because
# in that case all arguments were numbers, and broadcasting over only numbers
# isn't supported by base currently
function nullable_broadcast_shape(us::Union{Nullable,Number}...)
    for u in us
        if isa(us, Nullable)
            if u.isnull
                return true
            end
        end
    end
    return false
end

# Base's broadcast has a very loose signature so we can easily make it more
# specific. Broadcast on numbers is still not supported. FIXME: remove generated
# functions where unnecessary

# some specialized functions
broadcast{T}(f, u::Nullable{T}) =
    u.isnull ? Nullable{promote_op(f, T)}() : Nullable{promote_op(f, T)}(f(u.value))

@generated function broadcast(f, u::Union{Nullable,Number}, v::Union{Nullable,Number})
    checkfor(s) = :($s.isnull && return Nullable{result}())
    lifted = [T <: Nullable ? T.parameters[1] : T for T in (u, v)]
    checks = vcat(u <: Nullable ? [checkfor(:u)] : [],
                  v <: Nullable ? [checkfor(:v)] : [])
    quote
        result = promote_op(f, $(lifted...))
        $(checks...)
        @inbounds return Nullable{result}(f(u[], v[]))
    end
end

# functions with three arguments or more are a bit expensive to specialize...
# FIXME: why the arbitrary cutoff? justify
function broadcast(f, us::Union{Nullable, Number}...)
    result = promote_op(f,
        [T <: Nullable ? T.parameters[1] : T for T in map(typeof, us)]...)
    for u in us
        if isa(u, Nullable) && u.isnull
            return Nullable{result}()
        end
    end
    @inbounds return Nullable{result}(f(map(getindex, us)...))
end

# FIXME: these operations are probably not all correct
# and definitely some of them are slow, needs specialization
# also have to be careful to avoid ambiguities... needs testing
for eop in :(.+, .-, .*, ./, .\, .//, .==, .<, .!=, .<=, .÷, .%, .<<, .>>, .^).args
    @eval $eop(u::Nullable, v::Union{Nullable, Number}) = broadcast($eop, u, v)
    @eval $eop(u::Number, v::Nullable) = broadcast($eop, u, v)
end

end # module
