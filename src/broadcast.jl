using Base.Broadcast: check_broadcast_shape
# using Base.Cartesian

function gen_nullcheck(narrays::Int, nd::Int)
    e_nullcheck = macroexpand(:( @nref $nd isnull_1 d->j_d_1 ))
    for k = 2:narrays
        isnull = symbol("isnull_$k")
        j_d_k = symbol("j_d_$k")
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

function gen_broadcast_function(nd::Int, narrays::Int, f::Function, lift::Bool)
    As = [symbol("A_"*string(i)) for i = 1:narrays]
    body = gen_broadcast_body(nd, narrays, f, lift)
    # println(macroexpand( body ))
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

function Base.broadcast(f, As::NullableArray...;lift::Bool=false)
    return broadcast!(f, NullableArray(eltype(Base.promote_eltype(As...)),
                                       Base.Broadcast.broadcast_shape(As...)),
                      As...; lift=lift)
end

#----- broadcasted binary operations -----------------------------------------#

# The following require specialized implementations because the base/broadcast
# methods return BitArrays instead of similars of the arguments.
# An alternative to the following implementations is simply to let the base
# implementations use convert(::Type{Bool}, ::Nullable{Bool}), but this is
# slower.
for (op, scalar_op) in (
    (:.==, :(==)),
    (:.!=, :!=),
    (:.<, :<),
    (:.>, :>),
    (:.<=, :<=),
    (:.>=, :>=)
)
    @eval begin
        ($op)(X::NullableArray, Y::NullableArray) = broadcast($scalar_op, X, Y)
    end
end
