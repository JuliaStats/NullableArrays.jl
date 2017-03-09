# interface for skipping null entries
import Compat: @functorize

function skipnull_init(f, op, X::NullableArray,
                       ifirst::Int, ilast::Int)
    # Get first non-null element
    ifirst = Base.findnext(x -> x == false, X.isnull, ifirst)
    @inbounds v1 = X.values[ifirst]

    # Get next non-null element
    ifirst = Base.findnext(x -> x == false, X.isnull, ifirst + 1)
    @inbounds v2 = X.values[ifirst]

    # Reduce first two elements
    return op(f(v1), f(v2)), ifirst
end

# sequential map-reduce
function mapreduce_seq_impl_skipnull(f, op, X::NullableArray,
                                     ifirst::Int, ilast::Int)
    # initialize first reduction
    v, i = skipnull_init(f, op, X, ifirst, ilast)

    while i < ilast
        i += 1
        @inbounds isnull = X.isnull[i]
        isnull && continue
        @inbounds entry = X.values[i]
        v = op(v, f(entry))
    end
    return Nullable(v)
end

# pairwise map-reduce
function mapreduce_pairwise_impl_skipnull{T}(f, op, X::NullableArray{T},
                                             ifirst::Int, ilast::Int,
                                            #  n_notnull::Int, blksize::Int)
                                            blksize::Int)
    if ifirst + blksize > ilast
        # fall back to Base implementation if no nulls in block
        # if any(isnull, slice(X, ifirst:ilast))
            return mapreduce_seq_impl_skipnull(f, op, X, ifirst, ilast)
        # else
            # Nullable(Base.mapreduce_seq_impl(f, op, X.values, ifirst, ilast))
        # end
    else
        imid = (ifirst + ilast) >>> 1
        # n_notnull1 = imid - ifirst + 1 - countnz(X.isnull[ifirst:imid])
        # n_notnull2 = ilast - imid - countnz(X.isnull[imid+1:ilast])
        v1 = mapreduce_pairwise_impl_skipnull(f, op, X, ifirst, imid,
                                              blksize)
        v2 = mapreduce_pairwise_impl_skipnull(f, op, X, imid+1, ilast,
                                              blksize)
        return op(v1, v2)
    end
end

# from comment: https://github.com/JuliaLang/julia/pull/16217#issuecomment-223768129
if VERSION < v"0.5.0-dev+4441"
    sum_pairwise_blocksize = Base.sum_pairwise_blocksize
else
    sum_pairwise_blocksize(T) = Base.pairwise_blocksize(T, +)
end

mapreduce_impl_skipnull{T}(f, op, X::NullableArray{T}) =
    mapreduce_seq_impl_skipnull(f, op, X, 1, length(X.values))
mapreduce_impl_skipnull(f, op::typeof(@functorize(+)), X::NullableArray) =
    mapreduce_pairwise_impl_skipnull(f, op, X, 1, length(X.values),
                                   max(128, sum_pairwise_blocksize(f)))

# general mapreduce interface

function _mapreduce_skipnull{T}(f, op, X::NullableArray{T}, missingdata::Bool)
    n = length(X)
    !missingdata && return Nullable(Base.mapreduce_impl(f, op, X.values, 1, n))

    nnull = countnz(X.isnull)
    nnull == n && return Nullable(Base.mr_empty(f, op, T))
    @inbounds (nnull == n - 1 && return Nullable(Base.r_promote(op, f(X.values[findfirst(X.isnull, false)]))))
    #nnull == 0 && return Nullable(Base.mapreduce_impl(f, op, X.values, 1, n)) # there is missing data, so nnull>0

    return mapreduce_impl_skipnull(f, op, X)
end

function Base._mapreduce(f, op, X::NullableArray, missingdata)
    missingdata && return Base._mapreduce(f, op, X)
    Nullable(Base._mapreduce(f, op, X.values))
end

# to fix ambiguity warnings
function Base.mapreduce(f, op::Union{typeof(@functorize(&)), typeof(@functorize(|))},
                        X::NullableArray, skipnull::Bool = false)
    missingdata = any(isnull, X)
    if skipnull
        return _mapreduce_skipnull(f, op, X, missingdata)
    else
        return Base._mapreduce(f, op, X, missingdata)
    end
end


if VERSION >= v"0.5.0-dev+3701"
    const specialized_binary = identity
else
    const specialized_binary = Base.specialized_binary
end

"""
    mapreduce(f, op::Function, X::NullableArray; [skipnull::Bool=false])

Map a function `f` over the elements of `X` and reduce the result under the
operation `op`. One can set the behavior of this method to skip the null entries
of `X` by setting the keyword argument `skipnull` equal to true. If `skipnull`
behavior is enabled, `f` will be automatically lifted over the elements of `X`.
Note that, in general, mapreducing over a `NullableArray` will return a
`Nullable` object regardless of whether `skipnull` is set to `true` or `false`.
"""
function Base.mapreduce(f, op::Function, X::NullableArray;
                        skipnull::Bool = false)
    missingdata = any(isnull, X)
    if skipnull
        return _mapreduce_skipnull(f, specialized_binary(op),
                                   X, missingdata)
    else
        return Base._mapreduce(f, specialized_binary(op), X, missingdata)
    end
end

function Base.mapreduce(f, op, X::NullableArray; skipnull::Bool = false)
    missingdata = any(isnull, X)
    if skipnull
        return _mapreduce_skipnull(f, op, X, missingdata)
    else
        return Base._mapreduce(f, op, X, missingdata)
    end
end

"""
    reduce(op::Function, X::NullableArray; [skipnull::Bool=false])

Reduce `X`under the operation `op`. One can set the behavior of this method to
skip the null entries of `X` by setting the keyword argument `skipnull` equal
to true. If `skipnull` behavior is enabled, `f` will be automatically lifted
over the elements of `X`. Note that, in general, mapreducing over a
`NullableArray` will return a `Nullable` object regardless of whether `skipnull`
is set to `true` or `false`.
"""
Base.reduce(op, X::NullableArray; skipnull::Bool = false) =
    mapreduce(@functorize(identity), op, X; skipnull = skipnull)

# standard reductions

for (fn, op) in ((:(Base.sum), @functorize(+)),
                 (:(Base.prod), @functorize(*)),
                 (:(Base.minimum), @functorize(scalarmin)),
                 (:(Base.maximum), @functorize(scalarmax)))
    @eval begin
        # supertype(typeof(@functorize(abs))) returns Func{1} on Julia 0.4,
        # and Function on 0.5
        $fn(f::Union{Function,supertype(typeof(@functorize(abs)))},
            X::NullableArray;
            skipnull::Bool = false) =
                mapreduce(f, $op, X; skipnull = skipnull)
        $fn(X::NullableArray; skipnull::Bool = false) =
            mapreduce(@functorize(identity), $op, X; skipnull = skipnull)
    end
end

for (fn, f, op) in ((:(Base.sumabs), @functorize(abs), @functorize(+)),
                    (:(Base.sumabs2), @functorize(abs2), @functorize(+)))
    @eval $fn(X::NullableArray; skipnull::Bool = false) =
        mapreduce($f, $op, X; skipnull=skipnull)
end

# internal methods for Base.minimum and Base.maximum
for op in (@functorize(scalarmin), @functorize(scalarmax))
    @eval begin
        function Base._mapreduce{T}(::typeof(@functorize(identity)), ::$(typeof(op)),
                                    X::NullableArray{T}, missingdata)
            missingdata && return Nullable{T}()
            Nullable(Base._mapreduce(@functorize(identity), $op, X.values))
        end
    end
end

function Base.mapreduce_impl{T}(f, op::typeof(@functorize(scalarmin)), X::NullableArray{T},
                                first::Int, last::Int)
    i = first
    v = f(X[i])
    i += 1
    while i <= last
        @inbounds x = f(X[i])
        if isnull(x) | isnull(v)
            return Nullable{eltype(x)}()
        elseif x.value < v.value
            v = x
        end
        i += 1
    end
    return v
end

function Base.mapreduce_impl{T}(f, op::typeof(@functorize(scalarmax)), X::NullableArray{T},
                                first::Int, last::Int)
    i = first
    v = f(X[i])
    i += 1
    while i <= last
        @inbounds x = f(X[i])
        if isnull(x) | isnull(v)
            return Nullable{eltype(x)}()
        elseif x.value > v.value
            v = x
        end
        i += 1
    end
    return v
end

function Base.extrema{T}(X::NullableArray{T}; skipnull::Bool = false)
    length(X) > 0 || throw(ArgumentError("collection must be non-empty"))
    vmin = Nullable{T}()
    vmax = Nullable{T}()
    @inbounds for i in 1:length(X)
        x = X.values[i]
        null = X.isnull[i]
        if skipnull && null
            continue
        elseif null
            return (Nullable{T}(), Nullable{T}())
        elseif isnull(vmax) # Equivalent to isnull(vmin)
            vmax = vmin = Nullable(x)
        elseif x > vmax.value
            vmax = Nullable(x)
        elseif x < vmin.value
            vmin = Nullable(x)
        end
    end
    return (vmin, vmax)
end
