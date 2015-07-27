
NullableArrays.jl
=================
[![Build Status](https://travis-ci.org/johnmyleswhite/NullableArrays.jl.svg?branch=master)](https://travis-ci.org/johnmyleswhite/NullableArrays.jl)
[![Coverage Status](https://coveralls.io/repos/johnmyleswhite/NullableArrays.jl/badge.svg?branch=master)](https://coveralls.io/r/johnmyleswhite/NullableArrays.jl?branch=master)
[![codecov.io](http://codecov.io/github/davidagold/NullableArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/davidagold/NullableArrays.jl?branch=master)

NullableArrays.jl provides the `NullableArray{T, N}` type and its respective interface for use in storing and managing data with missing values.


`NullableArray{T, N}` is implemented as a subtype of `AbstractArray{Nullable{T}, N}` and inherits functionality from the `AbstractArray` interface.

The present repository is currently in a proto-typing stage of development, and the package is not officially registered. You can still obtain the package for your own use by cloning it in the REPL with:
```
Pkg.clone("https://github.com/johnmyleswhite/NullableArrays.jl.git")
```

Missing Values
==============
The central contribution of NullableArrays.jl is to provide a data structure that uses a single type, namely `Nullable{T}` to represent both present and missing values. `Nullable{T}` is a specialized container type that contains precisely either one or zero values. A `Nullable{T}` object that contains a value represents a present value of type `T` that, under other circumstances, might have been missing, whereas an empty `Nullable{T}` object represents a missing value that, under other circumstances, would have been of type `T` had it been present.

Indexing into an `NullableArray{T}` is thus "type-stable" in the sense that `getindex(X::NullableArray{T}, i)` will always return an object of type `Nullable{T}` regardless of whether the returned entry is present or missing. In general, this behavior more robustly supports the Julia compiler's ability to produce specialized lower-level code than do analogous data structures that use a token `NA` type to represent missingness. 

Constructors
============
There are a number of ways to construct a `NullableArray` object. Passing a single `Array{T, N}` object to the `NullableArray()` constructor will create a `NullableArray{T, N}` object with all present values:
```julia
julia> NullableArray([1:5...])
5-element NullableArrays.NullableArray{Int64,1}:
 Nullable(1)
 Nullable(2)
 Nullable(3)
 Nullable(4)
 Nullable(5)
 ```
 To indicate that certain values ought to be represented as missing, one can pass an additional `Array{Bool, N}` argument; any index `i` for which the latter argument contains a `true` entry will return an missing value from the resultant `NullableArray` object:
 ```julia
 julia> NullableArray([1:5...], [true, false, false, true, false])
5-element NullableArrays.NullableArray{Int64,1}:
 Nullable{Int64}()
 Nullable(2)      
 Nullable(3)      
 Nullable{Int64}()
 Nullable(5)  
 ```
 Note that the sizes of the two `Array` arguments passed to the above constructor method must be equal.
 
One can initialize an empty `NullableArray` object by calling `NullableArray(T, dims)`, where `T` is the desired element type of the resultant `NullableArray` and `dims` is either a tuple or sequence of integer arguments designating the size of the resultant `NullableArray`:

```julia
julia> NullableArray(Char, 3, 3)
3x3 NullableArrays.NullableArray{Char,2}:
 Nullable{Char}()  Nullable{Char}()  Nullable{Char}()
 Nullable{Char}()  Nullable{Char}()  Nullable{Char}()
 Nullable{Char}()  Nullable{Char}()  Nullable{Char}()
 ```
 
 One can also construct a `NullableArray` from a heterogeneous `Array` that uses a token object `x` to represent a missing value. For instance, if string `"NA"` represents a missing value in `[1, "NA", 2, 3, 5, "NA"]`, we can translate this pattern into a `NullableArray` object by passing to `NullableArray()` the latter `Array` object, the desired element type of the resultant `NullableArray` and the object that represents missingness in the first argument:
 ```julia
 julia> NullableArray([1, "NA", 2, 3, 5, "NA"], Int, "NA")
6-element NullableArrays.NullableArray{Int64,1}:
 Nullable(1)      
 Nullable{Int64}()
 Nullable(2)      
 Nullable(3)      
 Nullable(5)      
 Nullable{Int64}()
 ```


Implementation Details
======================
Under the hood of each `NullableArray{T, N}` object are two fields: a `values::Array{T, N}` field and an `isnull:Array{Bool, N}` field:
```julia
julia> fieldnames(NullableArray)
2-element Array{Symbol,1}:
 :values
 :isnull
 ```
The `isnull` array designates whether indexing into an `X::NullableArray` at a given index `i` ought to return a present or missing value. 
