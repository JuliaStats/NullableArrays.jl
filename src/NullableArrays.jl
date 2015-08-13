module NullableArrays

    using Reexport
    @reexport using Base.Cartesian

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
    include("map.jl")
    include("nullablevector.jl")
    include("operators.jl")
    include("broadcast.jl")
    include("reduce.jl")
    include("statistics.jl")
    include("show.jl")

    pkg_dir = Pkg.dir("NullableArrays")
    include(joinpath(pkg_dir, "perf/BenchmarkUtils.jl"))
end
