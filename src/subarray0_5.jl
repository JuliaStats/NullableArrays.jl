typealias NullableSubArray{T,N,P<:NullableArray,IV,LD} SubArray{T,N,P,IV,LD}

@inline function Base.isnull(V::NullableSubArray, I::Int...)
    @boundscheck checkbounds(V, I...)
    @inbounds return V.parent.isnull[Base.reindex(V, V.indexes, I)...]
end

@inline function Base.values(V::NullableSubArray, I::Int...)
    @boundscheck checkbounds(V, I...)
    @inbounds return V.parent.values[Base.reindex(V, V.indexes, I)...]
end

typealias FastNullableSubArray{T,N,P<:NullableArray,IV} SubArray{T,N,P,IV,true}

@inline function Base.isnull(V::FastNullableSubArray, i::Int)
    @boundscheck checkbounds(V, i)
    @inbounds return V.parent.isnull[V.first_index + V.stride1*i-1]
end

@inline function Base.values(V::FastNullableSubArray, i::Int)
    @boundscheck checkbounds(V, i)
    @inbounds return V.parent.values[V.first_index + V.stride1*i-1]
end

# We can avoid a multiplication if the first parent index is a Colon or UnitRange
typealias FastNullableContiguousSubArray{T,N,P<:NullableArray,I<:Tuple{Union{Colon, UnitRange}, Vararg{Any}}} SubArray{T,N,P,I,true}

@inline function Base.isnull(V::FastNullableContiguousSubArray, i::Int)
    @boundscheck checkbounds(V, i)
    @inbounds return V.parent.isnull[V.first_index + i - 1]
end

@inline function Base.values(V::FastNullableContiguousSubArray, i::Int)
    @boundscheck checkbounds(V, i)
    @inbounds return V.parent.values[V.first_index + i - 1]
end
