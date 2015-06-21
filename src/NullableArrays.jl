module NullableArrays

    using  Base.Cartesian

    export NullableArray,
           NullableVector,
           NullableMatrix,

           # Methods
           dropnull,
           anynull,
           allnull,
           head,
           nullify!,
           tail

    include("01_typedefs.jl")
    include("02_constructors.jl")
    include("03_primitives.jl")
    include("04_indexing.jl")
    include("05_map.jl")
    include("nullablevector.jl")
end
