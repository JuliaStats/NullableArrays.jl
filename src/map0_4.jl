Base.promote_shape(X1::NullableArray, X2::NullableArray) = promote_shape(size(X1), size(X2))

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


function map_to!{T,F}(f::F, offs, st, dest::AbstractArray{T}, A)
    # map to dest array, checking the type of each result. if a result does not
    # match, widen the result type and re-dispatch.
    i = offs
    while !done(A, st)
        @inbounds Ai, st = next(A, st)
        el = f(Ai)
        S = typeof(el)
        if S === T || S <: T
            @inbounds dest[i] = el::T
            i += 1
        else
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to!(f, i+1, st, new, A)
        end
    end
    return dest
end

function map_to!{T,F}(f::F, offs, dest::AbstractArray{T}, A::AbstractArray, B::AbstractArray)
    for i = offs:length(A) #Fixme iter
        @inbounds Ai, Bi = A[i], B[i]
        el = f(Ai, Bi)
        S = typeof(el)
        if (S !== T) && !(S <: T)
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to!(f, i+1, new, A, B)
        end
        @inbounds dest[i] = el::T
    end
    return dest
end

function map_to_n!{T,F}(f::F, offs, dest::AbstractArray{T}, As)
    for i = offs:length(As[1])
        el = f(ith_all(i, As)...)
        S = typeof(el)
        if (S !== T) && !(S <: T)
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new,1, dest,1, i-1)
            @inbounds new[i] = el
            return map_to_n!(f, i+1, new, As)
        end
        @inbounds dest[i] = el::T
    end
    return dest
end
