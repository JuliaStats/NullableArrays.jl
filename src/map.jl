# if VERSION < v"0.5.0-dev+3294"
#     include("map0_4.jl")
# else
using Base: ith_all
if VERSION < v"0.5.0-dev+3294"
    include("map0_4.jl")
else
    using Base: collect_similar, Generator
end

macro nullcheck(Xs, nargs)
    res = :($(Xs)[1].isnull[i])
    for i = 2:nargs
        e = :($(Xs)[$i].isnull[i])
        res = Expr(:||, res, e)
    end
    return res
end

macro fcall(Xs, nargs)
    res = Expr(:call, :f)
    for i in 1:nargs
        push!(res.args, :($(Xs)[$i].values[i]))
    end
    return res
end

# Base.map!

Base.map!{F}(f::F, X::NullableArray; lift=false) = map!(f, X, X; lift=lift)
function Base.map!{F}(f::F, dest::NullableArray, X::NullableArray; lift=false)
    if lift
        for (i, j) in zip(eachindex(dest), eachindex(X))
            if X.isnull[j]
                dest.isnull[i] = true
            else
                dest.isnull[i] = false
                dest.values[i] = f(X.values[j])
            end
        end
    else
        for (i, j) in zip(eachindex(dest), eachindex(X))
            dest[i] = f(X[j])
        end
    end
    return dest
end

function Base.map!{F}(f::F, dest::NullableArray, X1::NullableArray,
                      X2::NullableArray; lift=false)
    if lift
        for (i, j, k) in zip(eachindex(dest), eachindex(X1), eachindex(X2))
            if X1.isnull[j] | X2.isnull[k]
                dest.isnull[i] = true
            else
                dest.isnull[i] = false
                dest.values[i] = f(X1.values[j], X2.values[k])
            end
        end
    else
        for (i, j, k) in zip(eachindex(dest), eachindex(X1), eachindex(X2))
            dest[i] = f(X1[j], X2[k])
        end
    end
    return dest
end

function Base.map!{F}(f::F, dest::NullableArray, Xs::NullableArray...; lift=false)
    _map!(f, dest, Xs, lift)
end


@generated function _map!{F, N}(f::F, dest::NullableArray, Xs::NTuple{N, NullableArray}, lift)
    return quote
        if lift
            for i in eachindex(dest)
                if @nullcheck Xs $N
                    dest.isnull[i] = true
                else
                    dest.isnull[i] = false
                    dest.values[i] = @fcall Xs $N
                end
            end
        else
            for i in eachindex(dest)
                dest[i] = f(ith_all(i, Xs)...)
            end
        end
        return dest
    end
end

# Base.map

if VERSION < v"0.5.0-dev+3294"
    function Base.map(f, X::NullableArray; lift=false)
        lift ? _liftedmap(f, X) : _map(f, X)
    end
    function Base.map(f, X1::NullableArray, X2::NullableArray; lift=false)
        lift ? _liftedmap(f, X1, X2) : _map(f, X1, X2)
    end
    function Base.map(f, Xs::NullableArray...; lift=false)
        lift ? _liftedmap(f, Xs) : _map(f, Xs...)
    end
else
    function Base.map(f, X::NullableArray; lift=false)
        lift ? _liftedmap(f, X) : collect_similar(X, Generator(f, X))
    end
    function Base.map(f, X1::NullableArray, X2::NullableArray; lift=false)
        lift ? _liftedmap(f, X1, X2) : collect(Generator(f, X1, X2))
    end
    function Base.map(f, Xs::NullableArray...; lift=false)
        lift ? _liftedmap(f, Xs) : collect(Generator(f, Xs...))
    end
end

function _liftedmap(f, X::NullableArray)
    len = length(X)
    # if X is empty, fall back on type inference
    len > 0 || return NullableArray{Base.return_types(f, (eltype(X),))[1], 1}()
    i = 1
    while X.isnull[i]
        i += 1
    end
    # if X is all null, fall back on type inference
    i <= len || return similar(X, Base.return_types(f, (eltype(X),))[1])
    v = f(X.values[i])
    dest = similar(X, typeof(v))
    dest[i] = v
    _liftedmap_to!(f, dest, X, i+1, len)
end

function _liftedmap(f, X1::NullableArray, X2::NullableArray)
    len = prod(promote_shape(X1, X2))
    len > 0 || return NullableArray{Base.return_types(f, (eltype(X1), eltype(X2))), 0}()
    i = 1
    while X1.isnull[i] | X2.isnull[i]
        i += 1
    end
    i <= len || return similar(X1, Base.return_types(f, (eltype(X1), eltype(X2))))
    v = f(X1.values[i], X2.values[i])
    dest = similar(X1, typeof(v))
    dest[i] = v
    _liftedmap_to!(f, dest, X1, X2, i+1, len)
end

@generated function _liftedmap{N}(f, Xs::NTuple{N, NullableArray})
    return quote
        shp = mapreduce(size, promote_shape, Xs)
        len = prod(shp)
        i = 1
        while @nullcheck Xs $N
            i += 1
        end
        i <= len || return similar(X1, Base.return_types(f, tuple([ eltype(X) for X in Xs ])))
        v = @fcall Xs $N
        dest = similar(Xs[1], typeof(v))
        dest[i] = v
        _liftedmap_to!(f, dest, Xs, i+1, len)
    end
end

function _liftedmap_to!{T}(f, dest::NullableArray{T}, X, offs, len)
    # map to dest array, checking the type of each result. if a result does not
    # match, widen the result type and re-dispatch.
    i = offs
    while i <= len
        @inbounds if X.isnull[i]
            i += 1; continue
        end
        @inbounds el = f(X.values[i])
        S = typeof(el)
        if S === T || S <: T
            @inbounds dest[i] = el::T
            i += 1
        else
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new, 1, dest, 1, i-1)
            @inbounds new[i] = el
            return map_to!(f, new, X, i+1, len)
        end
    end
    return dest
end

function _liftedmap_to!{T}(f, dest::NullableArray{T}, X1, X2, offs, len)
    i = offs
    while i <= len
        @inbounds if X1.isnull[i] | X2.isnull[i]
            i += 1; continue
        end
        @inbounds el = f(X1.values[i], X2.values[i])
        S = typeof(el)
        if S === T || S <: T
            @inbounds dest[i] = el::T
            i += 1
        else
            R = typejoin(T, S)
            new = similar(dest, R)
            copy!(new, 1, dest, 1, i-1)
            @inbounds new[i] = el
            return map_to!(f, new, X1, X2, i+1, len)
        end
    end
    return dest
end

@generated function _liftedmap_to!{T, N}(f, dest::NullableArray{T}, Xs::NTuple{N,NullableArray}, offs, len)
    return quote
        i = offs
        while i <= len
            @inbounds if @nullcheck Xs $N
                i += 1; continue
            end
            @inbounds el = @fcall Xs $N
            S = typeof(el)
            if S === T || S <: T
                @inbounds dest[i] = el::T
                i += 1
            else
                R = typejoin(T, S)
                new = similar(dest, R)
                copy!(new, 1, dest, 1, i-1)
                @inbounds new[i] = el
                return map_to!(f, new, Xs, i+1, len)
            end
        end
        return dest
    end
end
