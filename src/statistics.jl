using StatsBase

Base.mean(X::NullableArray; skipnull::Bool = false) =
    sum(X; skipnull = skipnull) /
        Nullable(length(X.isnull) - (skipnull * countnz(X.isnull)))

function Base.mean{T, W, V}(X::NullableArray{T}, w::WeightVec{W, V};
                            skipnull::Bool=false)
    if skipnull
        _X = NullableArray(X.values .* w.values, X.isnull)
        _w = NullableArray(w.values, X.isnull)
        return sum(_X; skipnull=true) / sum(_w; skipnull=true)
    else
        anynull(X) ? Nullable{T}() : Nullable(mean(X.values, w))
    end
end

function Base.mean{T, W, V<:NullableArray}(X::NullableArray{T},
                                           w::WeightVec{W, V};
                                           skipnull::Bool=false)
    if skipnull
        _X = X .* w.values
        _w = NullableArray(w.values, _X.isnull)
        return sum(_X; skipnull=true) / sum(_w; skipnull=true)
    else
        anynull(X) || anynull(w) ? Nullable{T}() :
                                   Nullable(mean(X.values, w.values.values))
    end
end


function Base.varm{T}(X::NullableArray{T}, m::Number; corrected::Bool=true,
                      skipnull::Bool=false)
    if skipnull
        n = length(X)

        nnull = countnz(X.isnull)
        nnull == n && return Nullable(convert(Base.momenttype(T), NaN))
        nnull == n-1 && return Nullable(
            convert(Base.momenttype(T),
                    abs2(X.values[Base.findnextnot(X.isnull, 1)] - m)/(1 - Int(corrected))
            )
        )
        /(nnull == 0 ? Nullable(Base.centralize_sumabs2(X.values, m, 1, n)) :
                       mapreduce_impl_skipnull(Base.CentralizedAbs2Fun(m),
                                               Base.AddFun(), X),
          Nullable(n - nnull - Int(corrected))
        )
    else
        any(X.isnull) && return Nullable{T}()
        Nullable(Base.varm(X.values, m; corrected=corrected))
    end
end

function Base.varm{T, U<:Number}(X::NullableArray{T}, m::Nullable{U};
                                 corrected::Bool=true, skipnull::Bool=false)
    m.isnull && throw(NullException())
    return varm(X, m.value; corrected=corrected, skipnull=skipnull)
end

function Base.varzm{T}(X::NullableArray{T}; corrected::Bool=true,
                       skipnull::Bool=false)
    n = length(X)
    nnull = skipnull ? countnz(X.isnull) : 0
    (n == 0 || n == nnull) && return Nullable(convert(Base.momenttype(T), NaN))
    return sumabs2(X; skipnull=skipnull) /
           Nullable((n - nnull - Int(corrected)))
end

function Base.var(X::NullableArray; corrected::Bool=true, mean=nothing,
         skipnull::Bool=false)

    (anynull(X) & !skipnull) && return Nullable{eltype(X)}()

    if mean == 0 || isequal(mean, Nullable(0))
        return Base.varzm(X; corrected=corrected, skipnull=skipnull)
    elseif mean == nothing
        return varm(X, Base.mean(X; skipnull=skipnull); corrected=corrected,
             skipnull=skipnull)
    elseif isa(mean, Union{Number, Nullable})
        return varm(X, mean; corrected=corrected, skipnull=skipnull)
    else
        error()
    end
end

function Base.stdm(X::NullableArray, m::Number;
                   corrected::Bool=true, skipnull::Bool=false)
    return sqrt(varm(X, m; corrected=corrected, skipnull=skipnull))
end

function Base.stdm{T<:Number}(X::NullableArray, m::Nullable{T};
                              corrected::Bool=true, skipnull::Bool=false)
    return sqrt(varm(X, m; corrected=corrected, skipnull=skipnull))
end

function Base.std(X::NullableArray; corrected::Bool=true,
                              mean=nothing, skipnull::Bool=false)
    return sqrt(var(X; corrected=corrected, mean=mean, skipnull=skipnull))
end
