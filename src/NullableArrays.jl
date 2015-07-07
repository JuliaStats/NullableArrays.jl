module NullableArrays

    using  Base.Cartesian

    export NullableArray,
           NullableVector,
           NullableMatrix,

           # Macros
           @^,

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
    include("map.jl")
    include("nullablevector.jl")
    include("io.jl")
    include("lift.jl")
    include("operators.jl")
    include("mapreduce.jl")
end
