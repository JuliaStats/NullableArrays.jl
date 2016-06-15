module FunctionalNullableOperations

# extends Base with operations that treat nullables as collections

importall Base
import Base: promote_op, LinearFast

length(x::Nullable) = x.isnull ? 0 : 1
endof(x::Nullable)  = length(x)

# indexing is either without index, or with 1 as index
# generalized linear indexing is not supported
# setindex! not supported because Nullable is immutable
linearindexing{T}(::Nullable{T}) = LinearFast()
function getindex(x::Nullable)
    @boundscheck x.isnull && throw(NullException())
    x.value
end
function getindex(x::Nullable, i::Integer)
    @boundscheck (x.isnull | (i ≠ 1)) && throw(BoundsError(i, x))
    x.value
end

# iteration protocol
start(x::Nullable) = 1
next(x::Nullable, i::Integer) = x.value, 0
done(x::Nullable, i::Integer) = x.isnull | (i == 0)

# higher-order functions
function filter{T}(p, x::Nullable{T})
    if x.isnull
        x
    elseif p(x.value)
        x
    else
        Nullable{T}()
    end
end
map{T}(f, x::Nullable{T}) = x.isnull ? Nullable{Union{}}() : Nullable(f(x.value))

function map(f, xs::Nullable...)
    if all(isnull, xs)
        Nullable()
    elseif !any(isnull, xs)
        Nullable(map(f, map(getindex, xs)...))
    else
        throw(DimensionMismatch("expected all null or all nonnull"))
    end
end

broadcast{T}(f, x::Nullable{T}) =
    x.isnull ? Nullable{promote_op(f, T)}() : Nullable{promote_op(f, T)}(f(x.value))

# FIXME: need fast implementation for 2/3? args

# generic multi-argument implementation
function broadcast(f, xs::Union{Nullable, Number}...)
    result = promote_op(f,
        [T <: Nullable ? T.parameters[1] : T for T in map(typeof, xs)]...)
    for x in xs
        if isa(x, Nullable) && x.isnull
            return Nullable{result}()
        end
    end
    @inbounds return Nullable{result}(f(map(getindex, xs)...))
end

# FIXME: these operations may be incorrect
# and definitely some of them are slow, needs specialization
# also have to be careful to avoid ambiguities... needs testing
for (eop, op) in ((:.+, :+), (:.-, :-), (:.*, :*), (:./, :/), (:.\, :\),
                  (:.//, ://), (:.==, :(==)), (:.<, :<), (:.!=, :!=),
                  (:.<=, :<=), (:.÷, :÷), (:.%, :%), (:.<<, :<<), (:.>>, :>>),
                  (:.^, :^))
    @eval $eop(x::Nullable, y::Union{Nullable, Number}) = broadcast($op, x, y)
    @eval $eop(x::Number, y::Nullable) = broadcast($op, x, y)
end

end # module
