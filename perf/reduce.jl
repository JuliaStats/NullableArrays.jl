using NullableArrays
using DataArrays

srand(1)
A = rand(5_000_000)
B = rand(Bool, 5_000_000)
mu_A = mean(A)
X = NullableArray(A)
Y = NullableArray(A, B)
D = DataArray(A)
E = DataArray(A, B)

f(x) = 5 * x
f{T<:Number}(x::Nullable{T}) =
    ifelse(isnull(x), Nullable{typeof(5 * x.value)}(), Nullable(5 * x.value))

#-----------------------------------------------------------------------------#

function profile_reduce_methods()
    A = rand(5_000_000)
    B = rand(Bool, 5_000_000)
    X = NullableArray(A)
    Y = NullableArray(A, B)
    D = DataArray(A)
    E = DataArray(A, B)

    profile_mapreduce(A, X, Y, D, E)
    profile_reduce(A, X, Y, D, E)

    for method in (
        sum,
        prod,
        minimum,
        maximum,
    )
        (method)(A)
        (method)(X)
        (method)(D)
        println("Method: $method(A) (0 missing entries)")
        print("  for Array{Float64}:          ")
        @time((method)(A))
        print("  for NullableArray{Float64}:  ")
        @time((method)(X))
        print("  for DataArray{Float64}:      ")
        @time((method)(D))
        println()

        (method)(f, A)
        (method)(f, X)
        (method)(f, D)
        println("Method: $method(f, A) (0 missing entries)")
        print("  for Array{Float64}:          ")
        @time((method)(f, A))
        print("  for NullableArray{Float64}:  ")
        @time((method)(f, X))
        print("  for DataArray{Float64}:      ")
        @time((method)(f, D))
        println()
    end

    for method in (
        sum,
        prod,
        minimum,
        maximum,
    )
        (method)(Y)
        println("Method: $method(A) (~half missing entries, skip=false)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(Y))
        (method)(E)
        print("  for DataArray{Float64}:      ")
        @time((method)(E))
        println()

        (method)(f, Y)
        println("Method: $method(f, A) (~half missing entries, skip=false)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(f, Y))
        if in(method, (sum, prod))
            (method)(f, E)
            print("  for DataArray{Float64}:      ")
            @time((method)(f, E))
        else
            println("  $method(f, A::DataArray) currently incurs error")
        end
        println()
    end

    for method in (
        sum,
        prod,
        minimum,
        maximum,
    )
        (method)(Y, skipnull=true)
        println("Method: $method(A) (~half missing entries, skip=true)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(Y, skipnull=true))
        (method)(E, skipna=true)
        print("  for DataArray{Float64}:      ")
        @time((method)(E, skipna=true))
        println()

        (method)(f, Y, skipnull=true)
        println("Method: $method(f, A) (~half missing entries, skip=true)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(f, Y, skipnull=true))
        (method)(f, E, skipna=true)
        print("  for DataArray{Float64}:      ")
        @time((method)(f, E, skipna=true))
        println()
    end

    for method in (
        sumabs,
        sumabs2
    )
        (method)(A)
        (method)(X)
        (method)(D)
        println("Method: $method(A) (0 missing entries)")
        print("  for Array{Float64}:          ")
        @time((method)(A))
        print("  for NullableArray{Float64}:  ")
        @time((method)(X))
        print("  for DataArray{Float64}:      ")
        @time((method)(D))
        println()
    end

    for method in (
        sumabs,
        sumabs2
    )
        (method)(Y)
        println("Method: $method(A) (~half missing entries, skip=false)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(Y))
        (method)(E)
        print("  for DataArray{Float64}:      ")
        @time((method)(E))
        println()
    end

    for method in (
        sumabs,
        sumabs2
    )
        (method)(Y, skipnull=true)
        println("Method: $method(A) (~half missing entries, skip=true)")
        print("  for NullableArray{Float64}:  ")
        @time((method)(Y, skipnull=true))
        (method)(E, skipna=true)
        print("  for DataArray{Float64}:      ")
        @time((method)(E, skipna=true))
        println()
    end
end


function profile_mapreduce(A, X, Y, D, E)
    println("Method: mapreduce(f, op, A) (0 missing entries)")
    mapreduce(f, Base.(:+), A)
    print("  for Array{Float64}:          ")
    @time(mapreduce(f, Base.(:+), A))
    mapreduce(f, Base.(:+), X)
    print("  for NullableArray{Float64}:  ")
    @time(mapreduce(f, Base.(:+), X))
    mapreduce(f, Base.(:+), D)
    print("  for DataArray{Float64}:      ")
    @time(mapreduce(f, Base.(:+), D))
    println()

    println("Method: mapreduce(f, op, A) (~half missing entries, skip=false)")
    mapreduce(f, Base.(:+), Y)
    print("  for NullableArray{Float64}:  ")
    @time(mapreduce(f, Base.(:+), Y))
    mapreduce(f, Base.(:+), E)
    print("  for DataArray{Float64}:      ")
    @time(mapreduce(f, Base.(:+), E))
    println()

    println("Method: mapreduce(f, op, A) (~half missing entries, skip=true)")
    mapreduce(f, Base.(:+), Y, skipnull=true)
    print("  for NullableArray{Float64}:  ")
    @time(mapreduce(f, Base.(:+), Y, skipnull=true))
    mapreduce(f, Base.(:+), E, skipna=true)
    print("  for DataArray{Float64}:      ")
    @time(mapreduce(f, Base.(:+), E, skipna=true))
    println()
end

function profile_reduce(A, X, Y, D, E)
    println("Method: reduce(f, op, A) (0 missing entries)")
    reduce(Base.(:+), A)
    print("  for Array{Float64}:          ")
    @time(reduce(Base.(:+), A))
    reduce(Base.(:+), X)
    print("  for NullableArray{Float64}:  ")
    @time(reduce(Base.(:+), X))
    reduce(Base.(:+), D)
    print("  for DataArray{Float64}:      ")
    @time(reduce(Base.(:+), D))
    println()

    println("Method: reduce(f, op, A) (~half missing entries, skip=false)")
    reduce(Base.(:+), Y)
    print("  for NullableArray{Float64}:  ")
    @time(reduce(Base.(:+), Y))
    reduce(Base.(:+), E)
    print("  for DataArray{Float64}:      ")
    @time(reduce(Base.(:+), E))
    println()

    println("Method: reduce(f, op, A) (~half missing entries, skip=true)")
    reduce(Base.(:+), Y, skipnull=true)
    print("  for NullableArray{Float64}:  ")
    @time(reduce(Base.(:+), Y, skipnull=true))
    reduce(Base.(:+), E, skipna=true)
    print("  for DataArray{Float64}:      ")
    @time(reduce(Base.(:+), E, skipna=true))
    println()
end

# # NullableArray vs. DataArray comparison
function profile_skip(skip::Bool)
    println("Comparison of skipnull/skipNA methods")
    println()
    println("f := identity, op := +")
    println("mapreduce(f, op, X; skipnull/skipNA=$skip) (0 missing entries)")

    mapreduce(identity, +, X, skipnull=skip)
    print("  for NullableArray{Float64}:  ")
    @time(mapreduce(identity, +, X, skipnull=skip))

    mapreduce(identity, +, D, skipna=skip)
    print("  for DataArray{Float64}:      ")
    @time(mapreduce(identity, +, D, skipna=skip))

    println()
    println("reduce(op, X; skipnull/skipNA=$skip) (0 missing entries)")
    reduce(+, X, skipnull=skip)
    print("  for NullableArray{Float64}:  ")
    @time(reduce(+, X, skipnull=skip))

    reduce(+, D, skipna=skip)
    print("  for DataArray{Float64}:      ")
    @time(reduce(+, D, skipna=skip))

    println()
    println("mapreduce(f, op, X; skipnull/skipNA=$skip) (~half missing entries)")
    mapreduce(identity, +, Y, skipnull=skip)
    print("  for NullableArray{Float64}:  ")
    @time(mapreduce(identity, +, Y, skipnull=skip))

    mapreduce(identity, +, E, skipna=skip)
    print("  for DataArray{Float64}:      ")
    @time(mapreduce(identity, +, E, skipna=skip))

    println()
    println("reduce(op, X; skipnull/skipNA=$skip) (~half missing entries)")
    reduce(+, Y, skipnull=skip)
    print("  for NullableArray{Float64}:  ")
    @time(reduce(+, Y, skipnull=skip))

    reduce(+, E, skipna=true)
    print("  for DataArray{Float64}:      ")
    @time(reduce(+, E, skipna=true))
    nothing
end

function profile_skip_impl()
    println("Comparison of internal skip methods:")
    println("mapreduce_impl_skipnull(f, op, X) (0 missing entries)")
    NullableArrays.mapreduce_impl_skipnull(identity, +, X)
    print("  for NullableArray{Float64}:  ")
    @time(NullableArrays.mapreduce_impl_skipnull(identity, +, X))

    DataArrays.mapreduce_impl_skipna(identity, +, D)
    print("  for DataArray{Float64}:      ")
    @time(DataArrays.mapreduce_impl_skipna(identity, +, D))

    println()
    println("mapreduce_impl_skipnull(f, op, X) (~half missing entries)")
    NullableArrays.mapreduce_impl_skipnull(identity, +, Y)
    print("  for NullableArray{Float64}:  ")
    @time(NullableArrays.mapreduce_impl_skipnull(identity, +, Y))

    DataArrays.mapreduce_impl_skipna(identity, +, E)
    print("  for DataArray{Float64}:      ")
    @time(DataArrays.mapreduce_impl_skipna(identity, +, E))
    nothing
end
