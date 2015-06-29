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
           findnull,
           global_mean,
           head,
           nullify!,
           padnull!,
           padnull,
           tail

    include("01_typedefs.jl")
    include("02_constructors.jl")
    include("03_primitives.jl")
    include("04_indexing.jl")
    include("05_map.jl")
    include("io.jl")
    include("lift.jl")
    include("linearalgebra.jl")
    include("nullablevector.jl")
end
