
#----- @^ --------------------------------------------------------------------#

macro ^(call, T...)
    arg_cache = Dict{Union{Symbol, Expr}, Expr}()
    if !(isa(call, Expr)) || call.head != :call
        throw(ArgumentError("@^: argument must be a function call"))
    end

    if length(T) == 0
        e_type = :(Union{})
    elseif length(T) == 1
        e_type = T[1]
    else
        throw(ArgumentError("@^: wrong number of arguments"))
    end

    e_call = gen_calls(call, arg_cache)
    args = collect(keys(arg_cache))
    e_nullcheck = :($(args[1]).isnull)
    for i = 2:length(args)
        e_nullcheck = Expr(:||, e_nullcheck, :($(args[i]).isnull))
    end

    return esc(:(
        if $e_nullcheck
            Nullable{$e_type}()
        else
            Nullable($e_call)
        end )
    )
end

# base case for literals
gen_calls(e, arg_cache) = e

# base case for symbols
function gen_calls(e::Symbol, arg_cache)
    new_arg = get!(arg_cache, e, :($e.value))
    return new_arg
end

# recursively modify expression tree
function gen_calls(e::Expr, arg_cache)
    if e.head == :call
        return Expr(:call, e.args[1], gen_calls(e.args[2:end], arg_cache)...)
    elseif e.head == :ref
        new_arg = get!(arg_cache, e, :($e.value))
        return new_arg
    else
        return e
    end
end

# recursive case for `args` field arrays
function gen_calls(args::Array, arg_cache)
    return [ gen_calls(arg, arg_cache) for arg in args ]
end
