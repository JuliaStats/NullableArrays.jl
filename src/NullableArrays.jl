module NullableArrays

    using  Base.Cartesian

    export NullableArray,
           NullableVector,
           NullableMatrix,

           # Macros

           # Methods
           dropnull,
           anynull,
           allnull,
           head,
           nullify!,
           padnull!,
           padnull,
           tail

    include("typedefs.jl")
    include("constructors.jl")
    include("primitives.jl")
    include("indexing.jl")
    include("nullablevector.jl")
    include("operators.jl")
    include("broadcast.jl")
    include("mapreduce.jl")
    include("statistics.jl")
end
