using Base.Cartesian

function gen_nullcheck(narrays::Int)
    As = [Symbol("A_"*string(i)) for i = 1:narrays]
    e_nullcheck = :($(As[1]).isnull[i])
    for i = 2:narrays
        e_nullcheck = Expr(:||, e_nullcheck, :($(As[i]).isnull[i]))
    end
    return e_nullcheck
end

function gen_map!_body{F}(narrays::Int, lift::Bool, f::F)
    _f = Expr(:quote, f)
    e_nullcheck = gen_nullcheck(narrays)
    if lift
        return quote
            for i in 1:length(dest)
                if $e_nullcheck
                    dest.isnull[i] = true
                else
                    dest[i] = $_f((@ntuple $narrays j->A_j.values[i])...)
                end
            end
        end
    else
        return quote
            for i in 1:length(dest)
                dest[i] = $_f((@ntuple $narrays j->A_j[i])...)
            end
        end
    end
end

function gen_map_to!_body{F}(_map_to!::Symbol, narrays::Int, f::F)
    _f = Expr(:quote, f)
    e_nullcheck = gen_nullcheck(narrays)
    return quote
        @inbounds for i in offs:length(A_1)
            if lift
                if $e_nullcheck
                    # we don't need to compute anything if A.isnull[i], since
                    # the return type is specified by T and by the algorithm in
                    # 'body'
                    dest.isnull[i] = true
                    continue
                else
                    v = $_f((@ntuple $narrays j->A_j.values[i])...)
                end
            else
                v = $_f((@ntuple $narrays j->A_j[i])...)
            end
            S = typeof(v)
            if S !== T && !(S <: T)
                R = typejoin(T, S)
                new = similar(dest, R)
                copy!(new, 1, dest, 1, i - 1)
                new[i] = v
                return $(_map_to!)(new, i + 1, (@ntuple $narrays j->A_j)...; lift=lift)
            end
            dest[i] = v::T
        end
        return dest
    end
end

function gen_map_body{F}(_map_to!::Symbol, narrays::Int, f::F)
    _f = Expr(:quote, f)
    e_nullcheck = gen_nullcheck(narrays)
    if narrays == 1
        pre = quote
            isempty(A_1) && return isa(f, Type) ? similar(A_1, f) : similar(A_1)
        end
    else
        pre = quote
            shape = mapreduce(size, promote_shape, (@ntuple $narrays j->A_j))
            prod(shape) == 0 && return similar(A_1, promote_type((@ntuple $narrays j->A_j)...), shape)
        end
    end
    return quote
        $pre
        i = 1
        # find first non-null entry in A_1, ... A_narrays
        if lift == true
            emptyel = $e_nullcheck
            while (emptyel && i < length(A_1))
                i += 1
                emptyel &= $e_nullcheck
            end
            # if all entries are null, return a similar
            i == length(A_1) && return isa(f, Type) ? similar(A_1, f) : similar(A_1)
            v = $_f((@ntuple $narrays j->A_j.values[i])...)
        else
            v = $_f((@ntuple $narrays j->A_j[i])...)
        end
        dest = similar(A_1, typeof(v))
        dest[i] = v
        return $(_map_to!)(dest, i + 1, (@ntuple $narrays j->A_j)...; lift=lift)
    end
end

function gen_map!_function{F}(narrays::Int, lift::Bool, f::F)
    As = [Symbol("A_"*string(i)) for i = 1:narrays]
    body = gen_map!_body(narrays, lift, f)
    @eval let
        local _F_
        function _F_(dest, $(As...))
            $body
        end
        _F_
    end
end

function gen_map_function{F}(_map_to!::Symbol, narrays::Int, f::F)
    As = [Symbol("A_"*string(i)) for i = 1:narrays]
    body_map_to! = gen_map_to!_body(_map_to!, narrays, f)
    body_map = gen_map_body(_map_to!, narrays, f)

    @eval let $_map_to! # create a closure for subsequent calls to $_map_to!
        function $(_map_to!){T}(dest::NullableArray{T}, offs, $(As...); lift::Bool=false)
            $body_map_to!
        end
        local _F_
        function _F_($(As...); lift::Bool=false)
            $body_map
        end
        return _F_
    end # let $_map_to!
end

# Base.map!
@eval let cache = Dict{Bool, Dict{Int, Dict{Base.Callable, Function}}}()
    @doc """
    `map!{F}(f::F, dest::NullableArray, As::AbstractArray...; lift::Bool=false)`
    This method implements the same behavior as that of `map!` when called on
    regular `Array` arguments. It also includes the `lift` keyword argument, which
    when set to true will lift `f` over the entries of the `As`. Lifting is
    disabled by default.
    """ ->
    function Base.map!{F}(f::F, dest::NullableArray, As::AbstractArray...;
                          lift::Bool=false)
        narrays = length(As)

        cache_lift  = Base.@get!  cache         lift    Dict{Int, Dict{Base.Callable, Function}}()
        cache_f     = Base.@get!  cache_lift    narrays Dict{Base.Callable, Function}()
        func        = Base.@get!  cache_f       f       gen_map!_function(narrays, lift, f)

        func(dest, As...)
        return dest
    end
end

Base.map!{F}(f::F, X::NullableArray; lift::Bool=false) = map!(f, X, X; lift=lift)

# Base.map
@eval let cache = Dict{Int, Dict{Base.Callable, Function}}()
    @doc """
    `map{F}(f::F, As::AbstractArray...; lift::Bool=false)`
    This method implements the same behavior as that of `map!` when called on
    regular `Array` arguments. It also includes the `lift` keyword argument, which
    when set to true will lift `f` over the entries of the `As`. Lifting is
    disabled by default.
    """ ->
    function Base.map{F}(f::F, As::NullableArray...; lift::Bool=false)
        narrays = length(As)
        _map_to! = gensym()

        cache_fs    = Base.@get!  cache     narrays  Dict{Base.Callable, Function}()
        _map        = Base.@get!  cache_fs  f        gen_map_function(_map_to!, narrays, f)

        return _map(As...; lift=lift)
    end
end
