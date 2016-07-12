using Base: promote_eltype

function _map(f, X)
    if isempty(X)
        return isa(f, Type) ? similar(X, f) : similar(X)
    end
    st = start(X)
    x1, st = next(X, st)
    first = f(x1)
    dest = similar(X, typeof(first))
    dest[1] = first
    return map_to!(f, 2, st, dest, X)
end

function _map(f, X1, X2)
    shp = promote_shape(size(X1), size(X2))
    if prod(shp) == 0
        return similar(X1, promote_type(eltype(X1), eltype(X2)), shp)
    end
    first = f(X1[1], X2[1])
    dest = similar(X1, typeof(first), shp)
    dest[1] = first
    return map_to!(f, 2, dest, X1, X2)
end

function _map(f, Xs...)
    shape = mapreduce(size, promote_shape, Xs)
    if prod(shape) == 0
        return similar(Xs[1], promote_eltype(Xs...), shape)
    end
    first = f(ith_all(1, Xs)...)
    dest = similar(Xs[1], typeof(first), shape)
    dest[1] = first
    return map_to_n!(f, 2, dest, Xs)
end


function map_to!{T,F}(f::F, offs, st, dest::NullableArray{T}, X)
    # map to dest array, checking the type of each result. if a result does not
    # match, widen the result type and re-dispatch.
    i = offs
    while !done(X, st)
        @inbounds Xi, st = next(X, st)
        el = f(Xi)
        S = typeof(el)
        if S === T || S <: T
            @inbounds dest[i] = el::T
            i += 1
        else
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to!(f, i+1, st, new, X)
        end
    end
    return dest
end

function map_to!{T,F}(f::F, offs, dest::NullableArray{T}, X1::NullableArray, X2::NullableArray)
    for i = offs:length(X1)
        @inbounds X1i, X2i = X1[i], X2[i]
        el = f(X1i, X2i)
        S = typeof(el)
        if (S !== T) && !(S <: T)
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to!(f, i+1, new, X1, X2)
        end
        @inbounds dest[i] = el::T
    end
    return dest
end

function map_to_n!{T,F}(f::F, offs, dest::NullableArray{T}, Xs)
    for i = offs:length(Xs[1])
        el = f(ith_all(i, Xs)...)
        S = typeof(el)
        if (S !== T) && !(S <: T)
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to_n!(f, i+1, new, Xs)
        end
        @inbounds dest[i] = el::T
    end
    return dest
end
