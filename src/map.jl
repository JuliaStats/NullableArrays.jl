using Base: collect_similar, Generator

call_map{F, N}(f::F, dest, As::Vararg{NullableArray, N}) =
    invoke(map!, Tuple{Function, AbstractArray, Vararg{AbstractArray, N}}, f, dest, As...)

"""
    map(f, As::NullableArray...)

Call `map` with nullable lifting semantics and return a `NullableArray`.
Lifting means calling function `f` on the the values wrapped inside `Nullable` entries
of the input arrays, and returning null if any entry is missing.

Note that this method's signature specifies the source `As` arrays as all
`NullableArray`s. Thus, calling `map` on arguments consisting
of both `Array`s and `NullableArray`s will fall back to the standard implementation
of `map` (i.e. without lifting).
"""
function Base.map{F, N}(f::F, As::Vararg{NullableArray, N})
    # These definitions are needed to avoid allocation due to splatting
    f2(x1) = lift(f, x1)
    f2(x1, x2) = lift(f, x1, x2)
    f2(x1, x2, x3) = lift(f, x1, x2, x3)
    f2(x1, x2, x3, x4) = lift(f, x1, x2, x3, x4)
    f2(x1, x2, x3, x4, x5) = lift(f, x1, x2, x3, x4, x5)
    f2(x1, x2, x3, x4, x5, x6) = lift(f, x1, x2, x3, x4, x5, x6)
    f2(x1, x2, x3, x4, x5, x6, x7) = lift(f, x1, x2, x3, x4, x5, x6, x7)
    f2(x...) = lift(f, x...)

    T = _default_eltype(Base.Generator{ziptype(As...), ftype(f2, As...)})
    if isleaftype(T) && !(T <: Nullable)
        dest = similar(Array{eltype(T)}, size(As[1]))
    else
        dest = similar(NullableArray{eltype(T)}, size(As[1]))
    end
    call_map(f2, dest, As...)
end

"""
    map!(f, dest::NullableArray, As::NullableArray...)

Call `map!` with nullable lifting semantics.
Lifting means calling function `f` on the the values wrapped inside `Nullable` entries
of the input arrays, and returning null if any entry is missing.

Note that this method's signature specifies the destination `dest` array as well as the
source `As` arrays as all `NullableArray`s. Thus, calling `map!` on a arguments
consisting of both `Array`s and `NullableArray`s will fall back to the standard implementation
of `map!` (i.e. without lifting).
"""
function Base.map!{F, N}(f::F, dest::NullableArray, As::Vararg{NullableArray, N})
    # These definitions are needed to avoid allocation due to splatting
    f2(x1) = lift(f, x1)
    f2(x1, x2) = lift(f, x1, x2)
    f2(x1, x2, x3) = lift(f, x1, x2, x3)
    f2(x1, x2, x3, x4) = lift(f, x1, x2, x3, x4)
    f2(x1, x2, x3, x4, x5) = lift(f, x1, x2, x3, x4, x5)
    f2(x1, x2, x3, x4, x5, x6) = lift(f, x1, x2, x3, x4, x5, x6)
    f2(x1, x2, x3, x4, x5, x6, x7) = lift(f, x1, x2, x3, x4, x5, x6, x7)
    f2(x...) = lift(f, x...)
    call_map(f2, dest, As...)
end

# This definition is needed to avoid dispatch loops going back to the above one
function Base.map!{F}(f::F, dest::NullableArray)
    f2(x1) = lift(f, x1)
    call_map(f2, dest, dest)
end
