#----- Base.mapreduce interface for skipping null entries --------------------#

function skipnull_init(f, op, isnull::Array, values::Array,
                       ifirst::Int, ilast::Int)
    # Get first non-null element
    ifirst = Base.findnext(x -> x == false, isnull, ifirst)
    @inbounds v1 = values[ifirst]

    # Get next non-null element
    ifirst = Base.findnext(x -> x == false, isnull, ifirst + 1)
    @inbounds v2 = values[ifirst]

    # Reduce first two elements
    return op(f(v1), f(v2)), ifirst
end

# sequential map-reduce
function mapreduce_seq_impl_skipnull(f, op, X::NullableArray,
                                     ifirst::Int, ilast::Int)
    # initialize first reduction
    v, i = skipnull_init(f, op, X.isnull, X.values, ifirst, ilast)

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
        # if anynull(slice(X, ifirst:ilast))
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

mapreduce_impl_skipnull{T}(f, op, X::NullableArray{T}) =
    mapreduce_seq_impl_skipnull(f, op, X, 1, length(X.values))
mapreduce_impl_skipnull(f, op::Base.AddFun, X::NullableArray) =
    mapreduce_pairwise_impl_skipnull(f, op, X, 1, length(X.values),
                                   max(128, Base.sum_pairwise_blocksize(f)))

## general mapreduce interface

function _mapreduce_skipnull{T}(f, op, X::NullableArray{T}, missingdata::Bool)
    n = length(X)
    !missingdata && return Nullable(Base.mapreduce_impl(f, op, X.values, 1, n))

    nnull = countnz(X.isnull)
    nnull == n && return Base.mr_empty(f, op, T)
    nnull == n - 1 && return Base.r_promote(op, f(X.values[findnext(x -> x == false), X, 1]))
    # nnull == 0 && return Base.mapreduce_impl(f, op, X, 1, n)

    return mapreduce_impl_skipnull(f, op, X)
end

function Base._mapreduce(f, op, X::NullableArray, missingdata)
    missingdata && return Base._mapreduce(f, op, X)
    Nullable(Base._mapreduce(f, op, X.values))
end

function Base.mapreduce(f, op::Function, X::NullableArray;
                        skipnull::Bool = false)
    missingdata = anynull(X)
    if skipnull
        return _mapreduce_skipnull(f, Base.specialized_binary(op),
                                   X, missingdata)
    else
        return Base._mapreduce(f, Base.specialized_binary(op), X, missingdata)
    end
end

function Base.mapreduce(f, op, X::NullableArray; skipnull::Bool = false)
    missingdata = anynull(X)
    if skipnull
        return _mapreduce_skipnull(f, op, X, missingdata)
    else
        return Base._mapreduce(f, op, X, missingdata)
    end
end

Base.reduce(op, X::NullableArray; skipnull::Bool = false) =
    mapreduce(Base.IdFun(), op, X; skipnull = skipnull)

#----- Standard reductions ---------------------------------------------------#

for (fn, op) in ((:(Base.sum), Base.AddFun()),
                 (:(Base.prod), Base.MulFun()),
                 (:(Base.minimum), Base.MinFun()),
                 (:(Base.maximum), Base.MaxFun()))
    @eval begin
        $fn(f::Union(Function,Base.Func{1}),
            X::NullableArray;
            skipnull::Bool = false) =
                mapreduce(f, $op, X; skipnull = skipnull)
        $fn(X::NullableArray; skipnull::Bool = false) =
            mapreduce(Base.IdFun(), $op, X; skipnull = skipnull)
    end
end

for (fn, f, op) in ((:(Base.sumabs), Base.AbsFun(), Base.AddFun()),
                    (:(Base.sumabs2), Base.Abs2Fun(), Base.AddFun()))
    @eval $fn(X::NullableArray; skipnull::Bool = false) =
        mapreduce($f, $op, X; skipnull=skipnull)
end

#----- Base.minimum / Base.maximum -------------------------------------------#

# internal methods
for Op in (:(Base.MinFun), :(Base.MaxFun))
    @eval begin
        function Base._mapreduce{T}(::Base.IdFun, ::$Op,
                                    X::NullableArray{T}, missingdata)
            missingdata && return Nullable{T}()
            Nullable(Base._mapreduce(Base.IdFun(), $Op(), X.values))
        end
    end
end

function Base.mapreduce_impl{T}(f, op::Base.MinFun, X::NullableArray{T},
                                first::Int, last::Int)
    # locate the first non-null entry
    i = first
    while X.isnull[i] && i <= last
        i += 1
    end
    @inbounds v = f(X[i])
    i += 1
    # find min
    while i <= last
        if !X.isnull[i]
            @inbounds x = f(X[i])
            if (x < v).value
                v = x
            end
        end
        i += 1
    end
    return v
end

function Base.mapreduce_impl{T}(f, op::Base.MaxFun, X::NullableArray{T},
                                first::Int, last::Int)
    # locate the first non-null entry
    i = first
    while X.isnull[i] && i <= last
        i += 1
    end
    @inbounds v = f(X[i])
    i += 1
    # find min
    while i <= last
        if !X.isnull[i]
            @inbounds x = f(X[i])
            if (x > v).value
                v = x
            end
        end
        i += 1
    end
    return v
end
