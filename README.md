
NullableArrays.jl
=================
[![Build Status](https://travis-ci.org/JuliaStats/NullableArrays.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/NullableArrays.jl)
[![codecov.io](http://codecov.io/github/JuliaStats/NullableArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaStats/NullableArrays.jl?branch=master)

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
julia> julia> NullableArray(collect(1:5))
5-element NullableArray{Int64,1}:
 1
 2
 3
 4
 5
 ```
 To indicate that certain values ought to be represented as missing, one can pass an additional `Array{Bool, N}` argument; any index `i` for which the latter argument contains a `true` entry will return an missing value from the resultant `NullableArray` object:
 ```julia
julia> X = NullableArray([1, 2, 3, 4, 5], [true, false, false, true, false])
5-element NullableArray{Int64,1}:
 #NULL
     2
     3
 #NULL
     5
 ```
 Note that the sizes of the two `Array` arguments passed to the above constructor method must be equal.
 
 `NullableArray`s are designed to look and feel like regular `Array`s where possible and appropriate. Thus `display`ing a `NullableArray` object prints the values of present entries and `#NULL` designator for missing entries. It is important to note, however, that there is no such `#NULL` object, and that indexing into a `NullableArray` *always* returns a `Nullable` object, regardless of whether the entry at the specified index is missing or present:

```julia
julia> X[1]
Nullable{Int64}()

julia> X[2]
Nullable(2)
```

One can initialize an empty `NullableArray` object by calling `NullableArray(T, dims)`, where `T` is the desired element type of the resultant `NullableArray` and `dims` is either a tuple or sequence of integer arguments designating the size of the resultant `NullableArray`:

```julia
julia> NullableArray(Char, 3, 3)
3x3 NullableArray{Char,2}:
 #NULL  #NULL  #NULL
 #NULL  #NULL  #NULL
 #NULL  #NULL  #NULL
 ```

Indexing
========
Indexing into a `NullableArray{T}` is just like indexing into a regular `Array{T}`, except that the returned object will always be of type `Nullable{T}` rather than type `T`. One can expect any indexing pattern that works on an `Array` to work on a `NullableArray`. This includes using a `NullableArray` to index into any container object that sufficiently implements the `AbstractArray` interface:
```julia
julia> A = [1:5...]
5-element Array{Int64,1}:
 1
 2
 3
 4
 5

julia> X = NullableArray([2, 3])
2-element NullableArray{Int64,1}:
 2
 3

julia> A[X]
2-element Array{Int64,1}:
 2
 3
 ```
 Note, however, that attempting to index into any such `AbstractArray` with a null value will incur an error:
```julia
julia> Y = NullableArray([2, 3], [true, false])
2-element NullableArray{Int64,1}:
 #NULL
     3      

julia> A[Y]
ERROR: NullException()
 in _checkbounds at /Users/David/.julia/v0.4/NullableArrays/src/indexing.jl:73
 in getindex at abstractarray.jl:424
 ```

Working with `Nullable`s
========================
Using objects of type `Nullable{T}` to represent both present and missing values of type `T` may present an unfamiliar experience to users who have never encountered such specialized container types. This section of the documentation is devoted to explaining the dynamics of working with and illustrating common use patterns involving `Nullable` objects.

A central concern is how to extend methods originally defined for non-`Nullable` arguments to take `Nullable` arguments.

Suppose for instance that I have a method
```julia
f(x::Float64, y::Float64) = exp(x * y)
```

that I wish to `map` over the two columns of `X::NullableArray{Float64, 2}`:
```julia
julia> X = NullableArray(rand(10, 2), rand(Bool, 10, 2))
10x2 NullableArray{Float64,2}:
     0.0962217      0.057771 
 #NULL              0.655217 
 #NULL          #NULL        
 #NULL              0.691814 
     0.219243       0.197571 
 #NULL              0.948356 
 #NULL              0.601794 
 #NULL          #NULL        
 #NULL              0.0927559
 #NULL          #NULL  
```
As one may expect, simply calling `map(f, X[:,1], X[:,2])` incurs a `MethodError`:
```julia
julia> map(f, X[:,1], X[:,2])
ERROR: MethodError: `f` has no method matching f(::Nullable{Float64}, ::Nullable{Float64})
 [inlined code] from /Users/David/.julia/v0.4/NullableArrays/src/map.jl:93
 in _F_ at /Users/David/.julia/v0.4/NullableArrays/src/map.jl:124
 in map at /Users/David/.julia/v0.4/NullableArrays/src/map.jl:172
```
Let `v, w` be two `Nullable{Float64}` objects. If both `v, w` are non-null, the convention is to have `f(v, w)` return a similarly non-null `Nullable{Float64}` object whose `value` field agrees with `f(v.value, w.value)`.  If either of `v, w` is null, the convention is to return an empty `Nullable{Float64}` object, i.e. to propogate the uncertainty introduced by the null argument. Providing a systematic means of extending `f` to `Nullable` arguments in such a way that satisfies the above behavior is sometimes called *lifting* `f` over `Nullable` arguments.

Arguably, the best way to lift existing methods over `Nullable` arguments is to use multiple dispatch. That is, one can very easily extend `f` to handle `Nullable{Float64}` arguments by simply defining an appropriate method:
```julia
function f(x::Nullable{Float64}, y::Nullable{Float64})
    if x.isnull | y.isnull
        return Nullable{Float64}()
    else
        return Nullable(f(x.value, y.value))
    end
end
```
Now `broadcast` works as one would expect:
```julia
julia> broadcast(f, X[:,1], X[:,2])
10-element NullableArray{Float64,1}:
     1.00557
 #NULL      
 #NULL      
 #NULL      
     1.04427
 #NULL      
 #NULL      
 #NULL      
 #NULL      
 #NULL 
```

The convention is not to support signatures of mixed `Nullable` and non `Nullable` arguments for solely the purposes of lifting. This reflects both conceptual concerns as well practical limitations -- in particular, to cover all possible combinations of `Nullable` and non-`Nullable` arguments for a signature of length N would require 2^N method definitions. If one finds that one is calling a function `f` on both `Nullable` and non-`Nullable` arguments, it is typically best to wrap the non-`Nullable` arguments into `Nullable` arguments and invoke the lifted version. Alternatively, one can instead pass their respective `value` fields to `f` -- **HOWEVER**, this approach is both less safe and less general and should only be used if one is certain that the `Nullable` arguments are non-null.

The present package also offers means of lifting a function `f` over the entries of a `NullableArray` `X` when the two are passed as arguments to methods such as `map`, `broadcast` or `mapreduce`. The former two (and their mutating variants) offer the `lift` keyword argument that will lift `f` over `X` without requiring the user to define a new method for `f`:

```julia
julia> g(x::Float64) = 2x
g (generic function with 1 method)

julia> map(g, X; lift=true)
10x2 NullableArray{Float64,2}:
     0.192443      0.115542
 #NULL             1.31043 
 #NULL         #NULL       
 #NULL             1.38363 
     0.438486      0.395142
 #NULL             1.89671 
 #NULL             1.20359 
 #NULL         #NULL       
 #NULL             0.185512
 #NULL         #NULL  
```

`mapreduce` and `reduce` both offer the `skipnull` keyword argument, which directs the method to skip over the null entries of the argument `NullableArray` when reducing. Because the null entries are disregarded, setting `skipnull=true` is taken to be an implicit request to lift the supplied method `f` over `X`:

```julia
julia> mapreduce(g, +, X[:,1]; skipnull=true)
Nullable(0.6309288649002225)
```

`NullableArray` Implementation Details
======================
Under the hood of each `NullableArray{T, N}` object are two fields: a `values::Array{T, N}` field and an `isnull:Array{Bool, N}` field:
```julia
julia> fieldnames(NullableArray)
2-element Array{Symbol,1}:
 :values
 :isnull
 ```
The `isnull` array designates whether indexing into an `X::NullableArray` at a given index `i` ought to return a present or missing value.
