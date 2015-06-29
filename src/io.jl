# Experiments with different means of printing present and missing Nullable
# values to the screen

function Base.show{T}(io::IO, x::Nullable{T})
    print(io, ifelse(x.isnull, "?{$T}", "$(x.value)?"))
end
