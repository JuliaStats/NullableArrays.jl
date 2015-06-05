module NullableArrays
    export NullableArray, NullableVector, NullableMatrix

    include("01_typedefs.jl")
    include("02_constructors.jl")
    include("03_primitives.jl")
    include("04_indexing.jl")
end
