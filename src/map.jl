
#----- Base.map!/Base.map ----------------------------------------------------#

function Base.map!{F}(f::F,
                      dest::NullableArray,
                      A::AbstractArray) # -> NullableArray{T, N}
    local func
    function func(dest, A)
        for i in 1:length(dest)
            dest[i] = f(A[i])
        end
    end
    func(dest, A)
    dest
end

function map_to!{T, F}(f::F,
                       offs,
                       dest::NullableArray{T},
                       A::AbstractArray) # -> NullableArray{T, N}
    local func
    function func{T}(offs, dest::NullableArray{T}, A)
        @inbounds for i in offs:length(A)
            el = f(A[i])
            S = typeof(el)
            if S !== T && !(S <: T)
                R = typejoin(T, S)
                new = similar(dest, R)
                copy!(new, 1, dest, 1, i - 1)
                new[i] = el
                return func(i+1, new, A)
            end
            dest[i] = el::T
        end
        return dest
    end
    func(offs, dest, A)
end

function Base.map(f, X::NullableArray) # -> NullableArray{T, N}
    if isempty(X)
        return isa(f, Type) ? similar(X, f) : similar(X)
    else
        first = f(X[1])
        dest = similar(X, typeof(first))
        dest[1] = first
        return map_to!(f, 2, dest, X)
    end
end

# 2 arg
function Base.map!{F}(f::F,
                      dest::NullableArray,
                      A::AbstractArray,
                      B::AbstractArray) # -> NullableArray{T, N}
    local func
    function func(dest, A, B)
        for i in 1:length(dest)
            dest[i] = f(A[i], B[i])
        end
    end
    func(dest, A, B)
    dest
end

function map_to!{T, F}(f::F, offs,
                       dest::NullableArray{T},
                       A::AbstractArray,
                       B::AbstractArray) # -> NullableArray{T, N}
    local func
    function func{T}(offs, dest::NullableArray{T}, A, B)
        @inbounds for i in offs:length(A)
            el = f(A[i], B[i])
            S = typeof(el)
            if S !== T && !(S <: T)
                R = typejoin(T, S)
                new = similar(dest, R)
                copy!(new, 1, dest, 1, i - 1)
                new[i] = el
                return func(i+1, new, A, B)
            end
            dest[i] = el::T
        end
        return dest
    end
    func(offs, dest, A, B)
end

function Base.map(f, X::NullableArray, Y::NullableArray) # -> NullableArray{T, N}
    shape = promote_shape(size(X), size(Y))
    if prod(shape) == 0
        return similar(X, promote_type(eltype(X), eltype(Y)), shape)
    else
        first = f(X[1], f(Y[1]))
        dest = similar(X, typeof(first))
        # dest[1] = first
        return map_to!(f, 1, dest, X, Y)
    end
end

# N-args
function map_n!{F}(f::F,
                      dest::NullableArray,
                      As) # -> NullableArray{T, N}
    local func
    function func(dest, As)
        for i in 1:length(dest)
            dest[i] = f(Base.ith_all(i, As)...)
        end
    end
    func(dest, As)
    dest
end

function Base.map!{F}(f::F, dest::NullableArray, As::AbstractArray...)
    return map_n!(f, dest, As)
end

function map_to_n!{T, F}(f::F, offs,
                       dest::NullableArray{T},
                       As) # -> NullableArray{T, N}
    local func
    function func{T}(offs, dest::NullableArray{T}, As)
        @inbounds for i in offs:length(As[1])
            el = f(Base.ith_all(i, As)...)
            S = typeof(el)
            if S !== T && !(S <: T)
                R = typejoin(T, S)
                new = similar(dest, R)
                copy!(new, 1, dest, 1, i - 1)
                new[i] = el
                return func(i+1, new, As)
            end
            dest[i] = el::T
        end
        return dest
    end
    func(offs, dest, As)
end

function Base.map(f, Xs::NullableArray...) # -> NullableArray{T, N}
    shape = mapreduce(size, promote_shape, Xs)
    if prod(shape) == 0
        return similar(X[1], promote_type(Xs...), shape)
    else
        first = f(Base.ith_all(1, Xs)...)
        dest = similar(Xs[1], typeof(first), shape)
        dest[1] = first
        return map_to_n!(f, 1, dest, Xs)
    end
end
