const unsafe_getindex = Base.unsafe_getindex

@generated function Base.isnull{T,N,P<:NullableArray,IV,LD}(V::SubArray{T,N,P,IV,LD}, I::Int...)
    ni = length(I)
    if ni == 1 && length(IV.parameters) == LD  # linear indexing
        meta = Expr(:meta, :inline)
        if iscontiguous(V)
            return :($meta; Base.getindex(V.parent.isnull, V.first_index + I[1] - 1))
        end
        return :($meta; Base.getindex(V.parent.isnull, V.first_index + V.stride1*(I[1]-1)))
    end
    Isyms = [:(I[$d]) for d = 1:ni]
    exhead, idxs = Base.index_generate(ndims(P), IV, :V, Isyms)
    quote
        $exhead
        Base.getindex(V.parent.isnull, $(idxs...))
    end
end

@generated function Base.values{T,N,P<:NullableArray,IV,LD}(V::SubArray{T,N,P,IV,LD}, I::Int...)
    ni = length(I)
    if ni == 1 && length(IV.parameters) == LD  # linear indexing
        meta = Expr(:meta, :inline)
        if iscontiguous(V)
            return :($meta; Base.getindex(V.parent.values, V.first_index + I[1] - 1))
        end
        return :($meta; Base.getindex(V.parent.values, V.first_index + V.stride1*(I[1]-1)))
    end
    Isyms = [:(I[$d]) for d = 1:ni]
    exhead, idxs = Base.index_generate(ndims(P), IV, :V, Isyms)
    quote
        $exhead
        Base.getindex(V.parent.values, $(idxs...))
    end
end

@generated function anynull{T, N, U<:NullableArray}(S::SubArray{T, N, U})
    return quote
        isnull = slice(S.parent.isnull, S.indexes...)
        @nloops $N i S begin
            (@nref $N isnull i) && (return true)
        end
        return false
    end
end
