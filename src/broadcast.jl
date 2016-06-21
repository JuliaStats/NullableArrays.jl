using Base.Broadcast: check_broadcast_shape
using Base.Cartesian

if VERSION < v"0.5.0-dev+4724"
    function gen_nullcheck(narrays::Int, nd::Int)
        e_nullcheck = macroexpand(:( @nref $nd isnull_1 d->j_d_1 ))
        for k = 2:narrays
            isnull = Symbol("isnull_$k")
            j_d_k = Symbol("j_d_$k")
            e_isnull_k = macroexpand(:( @nref $nd $(isnull) d->$(j_d_k) ))
            e_nullcheck = Expr(:||, e_nullcheck, e_isnull_k)
        end
        return e_nullcheck
    end

    function gen_broadcast_body(nd::Int, narrays::Int, f, lift::Bool)
        F = Expr(:quote, f)
        e_nullcheck = gen_nullcheck(narrays, nd)
        if lift
            return quote
                # set up aliases to facilitate subsequent Base.Cartesian magic
                B_isnull = B.isnull
                @nexprs $narrays k->(values_k = A_k.values)
                @nexprs $narrays k->(isnull_k = A_k.isnull)
                # check size
                @assert ndims(B) == $nd
                @ncall $narrays Base.Broadcast.check_broadcast_shape size(B) k->A_k
                # main loops
                @nloops($nd, i, B,
                    d->(@nexprs $narrays k->(j_d_k = size(A_k, d) == 1 ? 1 : i_d)), # pre
                    begin # body
                        if $e_nullcheck
                            @inbounds (@nref $nd B_isnull i) = true
                        else
                            @nexprs $narrays k->(@inbounds v_k = @nref $nd values_k d->j_d_k)
                            @inbounds (@nref $nd B i) = (@ncall $narrays $F v)
                        end
                    end
                )
            end
        else
            return Base.Broadcast.gen_broadcast_body_cartesian(nd, narrays, f)
        end
    end

    function gen_broadcast_function(nd::Int, narrays::Int, f, lift::Bool)
        As = [Symbol("A_"*string(i)) for i = 1:narrays]
        body = gen_broadcast_body(nd, narrays, f, lift)
        @eval let
            local _F_
            function _F_(B, $(As...))
                $body
            end
            _F_
        end
    end

    function Base.broadcast!(f, X::NullableArray; lift::Bool=false)
        broadcast!(f, X, X; lift=lift)
    end

    @eval let cache = Dict{Any, Dict{Bool, Dict{Int, Dict{Int, Any}}}}()
        @doc """
        `broadcast!(f, B::NullableArray, As::NullableArray...; lift::Bool=false)`
        This method implements the same behavior as that of `broadcast!` when called on
        regular `Array` arguments. It also includes the `lift` keyword argument, which
        when set to true will lift `f` over the entries of the `As`.

        Lifting is disabled by default. Note that this method's signature specifies
        the destination `B` array as well as the source `As` arrays as all
        `NullableArray`s. Thus, calling `broadcast!` on a arguments consisting
        of both `Array`s and `NullableArray`s will fall back to the implementation
        of `broadcast!` in `base/broadcast.jl`.
        """ ->
        function Base.broadcast!(f, B::NullableArray, As::NullableArray...; lift::Bool=false)
            nd = ndims(B)
            narrays = length(As)

            cache_f    = Base.@get! cache      f       Dict{Bool, Dict{Int, Dict{Int, Any}}}()
            cache_lift = Base.@get! cache_f    lift    Dict{Int, Dict{Int, Any}}()
            cache_f_na = Base.@get! cache_lift narrays Dict{Int, Any}()
            func       = Base.@get! cache_f_na nd      gen_broadcast_function(nd, narrays, f, lift)

            func(B, As...)
            return B
        end
    end  # let cache
else
    using Base.Broadcast: newindexer, newindex

    function _nullcheck(nargs)
        nullcheck = :(isnull_1[I_1])
        for i in 2:nargs
            sym_isnull = Symbol("isnull_$i")
            sym_idx = Symbol("I_$i")
            nullcheck = Expr(:||, :($sym_isnull[$sym_idx]), nullcheck)
        end
        # if 0 argument arrays, treat nullcheck as though it returns false
        nargs >= 1 ? nullcheck : :(false)
    end

    @generated function Base.Broadcast._broadcast!{M,XT,nargs}(f,
    Z::NullableArray, indexmaps::M, Xs::XT, ::Type{Val{nargs}}; lift=false)
        nullcheck = _nullcheck(nargs)
        quote
            T = eltype(Z)
            $(Expr(:meta, :noinline))
            if !lift
                # destructure the indexmaps and As tuples
                @nexprs $nargs i->(X_i = Xs[i])
                @nexprs $nargs i->(imap_i = indexmaps[i])
                @simd for I in CartesianRange(indices(Z))
                    # reverse-broadcast the indices
                    @nexprs $nargs i->(I_i = newindex(I, imap_i))
                    # extract array values
                    @nexprs $nargs i->(@inbounds val_i = X_i[I_i])
                    # call the function and store the result
                    @inbounds Z[I] = @ncall $nargs f val
                end
            else
                # destructure the indexmaps and Xs tuples
                @nexprs $nargs i->(values_i = Xs[i].values)
                @nexprs $nargs i->(isnull_i = Xs[i].isnull)
                @nexprs $nargs i->(imap_i = indexmaps[i])
                @simd for I in CartesianRange(indices(Z))
                    # reverse-broadcast the indices
                    @nexprs $nargs i->(I_i = newindex(I, imap_i))
                    if $nullcheck
                        # if any args are null, store null
                        @inbounds Z[I] = Nullable{T}()
                    else
                        # extract array values
                        @nexprs $nargs i->(@inbounds val_i = values_i[I_i])
                        # call the function and store the result
                        @inbounds Z[I] = @ncall $nargs f val
                    end
                end
            end
        end
    end

    @doc """
    `broadcast!(f, B::NullableArray, As::NullableArray...; lift::Bool=false)`

    This method implements the same behavior as that of `broadcast!` when called
    on regular `Array` arguments. It also includes the `lift` keyword argument,
    which when set to true will lift `f` over the entries of the `As`.

    Lifting is disabled by default. Note that this method's signature specifies
    the destination `B` array as well as the source `As` arrays as all
    `NullableArray`s. Thus, calling `broadcast!` on a arguments consisting of
    both `Array`s and `NullableArray`s will fall back to the implementation of
    `broadcast!` in `base/broadcast.jl`.
    """ ->
    @inline function Base.broadcast!(f, Z::NullableArray, Xs::NullableArray...;
                                     lift=false)
        nargs = length(Xs)
        sz = size(Z)
        check_broadcast_shape(sz, Xs...)
        mapindex = map(x->newindexer(sz, x), Xs)
        Base.Broadcast._broadcast!(f, Z, mapindex, Xs, Val{nargs}; lift=lift)
        Z
    end
end

@doc """
`broadcast(f, As::NullableArray...;lift::Bool=false)`

This method implements the same behavior as that of `broadcast` when called on
regular `Array` arguments. It also includes the `lift` keyword argument, which
when set to true will lift `f` over the entries of the `As`.

Lifting is disabled by default. Note that this method's signature specifies the
source `As` arrays as all `NullableArray`s. Thus, calling `broadcast!` on
arguments consisting of both `Array`s and `NullableArray`s will fall back to the
implementation of `broadcast` in `base/broadcast.jl`.
""" ->
@inline function Base.broadcast(f, Xs::NullableArray...;lift::Bool=false)
    return broadcast!(f, NullableArray(eltype(Base.promote_eltype(Xs...)),
                                       Base.Broadcast.broadcast_shape(Xs...)),
                      Xs...; lift=lift)
end

# broadcasted ops
for (op, scalar_op) in (
    (:(@compat Base.:(.==)), :(==)),
    (:(@compat Base.:.!=), :!=),
    (:(@compat Base.:.<), :<),
    (:(@compat Base.:.>), :>),
    (:(@compat Base.:.<=), :<=),
    (:(@compat Base.:.>=), :>=)
)
    @eval begin
        ($op)(X::NullableArray, Y::NullableArray) = broadcast($scalar_op, X, Y)
    end
end
