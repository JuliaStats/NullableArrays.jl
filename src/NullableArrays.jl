VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module NullableArrays

using Compat
using Compat.view
using Reexport
@reexport using Base.Cartesian

export AbstractNullableArray, AbstractNullableVector, AbstractNullableMatrix,
       NullableArray, NullableVector, NullableMatrix,

       # Macros

       # Methods
       dropnull,
       anynull,
       allnull,
       nullify!,
       padnull!,
       padnull

include("typedefs.jl")
include("constructors.jl")
include("primitives.jl")
include("indexing.jl")
include("map.jl")
include("nullablevector.jl")
include("operators.jl")
include("broadcast.jl")
include("reduce.jl")
include("show.jl")
include("subarray.jl")

end
