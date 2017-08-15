VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module NullableArrays

using Compat
using Compat.view
using Reexport
using StatsBase
@reexport using Base.Cartesian

export NullableArray,
       NullableVector,
       NullableMatrix,

       # Macros

       # Methods
       dropnull,
       dropnull!,
       nullify!,
       padnull!,
       padnull

include("typedefs.jl")
include("constructors.jl")
include("primitives.jl")
include("indexing.jl")
include("operators.jl")
include("lift.jl")
include("map.jl")
include("nullablevector.jl")
include("broadcast.jl")
include("reduce.jl")
include("show.jl")
include("subarray.jl")
include("deprecated.jl")
include("utils.jl")

end
