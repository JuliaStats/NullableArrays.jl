module TestFunctional

# nullable equality is a little strange... we need a "is a null with type T"
# and a "is a nullable with value egal to k"

# these functions are curried for readability
isnull_typed(u::Nullable, T::Type) = typeof(u).parameters[1] == T && isnull(u)
isnull_typed(t::Type) = u -> isnull_typed(u, t)

isnullableof(u::Nullable, x) = !isnull(u) && u.value === x
isnullableof(x) = u -> isnullableof(u, x)

using Base.Test

# getindex
@test_throws NullException Nullable()[]
@test_throws NullException Nullable{Int}()[]
@test Nullable(0)[] == 0

@test_throws BoundsError Nullable()[1]
@test_throws BoundsError Nullable(0)[0]
@test_throws BoundsError Nullable(0)[2]
@test Nullable(0)[1] == 0

# collect
@test collect(Nullable()) == Union{}[]
@test collect(Nullable{Int}()) == Int[]
@test collect(Nullable(85)) == Int[85]
@test collect(Nullable(1.0)) == Float64[1.0]

# length
@test length(Nullable()) == 0
@test length(Nullable{Int}()) == 0
@test length(Nullable(1.0)) == 1
@test endof(Nullable(85)) == 1

# filter
for p in (_ -> true, _ -> false)
    @test filter(p, Nullable())      |> isnull_typed(Union{})
    @test filter(p, Nullable{Int}()) |> isnull_typed(Int)
end
@test filter(_ -> true, Nullable(85))  |> isnullableof(85)
@test filter(_ -> false, Nullable(85)) |> isnull_typed(Int)
@test filter(x -> x > 0, Nullable(85)) |> isnullableof(85)
@test filter(x -> x < 0, Nullable(85)) |> isnull_typed(Int)

# map
sqr(x) = x^2
@test map(sqr, Nullable())      |> isnull_typed(Union{})
@test map(sqr, Nullable{Int}()) |> isnull_typed(Union{})  # type-unstable (!)
@test map(sqr, Nullable(2))     |> isnullableof(4)

@test map(+, Nullable(1), Nullable(2), Nullable(3)) |> isnullableof(6)
@test map(+, Nullable(), Nullable(), Nullable())    |> isnull_typed(Union{})
@test map(+, Nullable{Int}(), Nullable{Int}())      |> isnull_typed(Union{})

# example: square if value exists, -1 if value is null
# with foldl/foldr/reduce
for fn in (foldl, foldr, reduce)
    @test foldl((_, x) -> x^2, -1, Nullable())   == -1
    @test foldl((_, x) -> x^2, -1, Nullable(10)) == 100
end

# with broadcast and get (map does not work because of get limitations...)
# perhaps the get limitations should be fixed
@test get(sqr.(Nullable{Int}()), -1) == -1
@test get(sqr.(Nullable(10)), -1)    == 100

# broadcast and elementwise
@test sin.(Nullable(0.0))             |> isnullableof(0.0)
@test sin.(Nullable{Float64}())       |> isnull_typed(Float64)

@test Nullable(8) .+ Nullable(10)     |> isnullableof(18)
@test Nullable(8) .- Nullable(10)     |> isnullableof(-2)
@test Nullable(8) .+ Nullable{Int}()  |> isnull_typed(Int)
@test Nullable{Int}() .- Nullable(10) |> isnull_typed(Int)

@test log.(10, Nullable(1.0))         |> isnullableof(0.0)
@test log.(10, Nullable{Float64}())   |> isnull_typed(Float64)

@test Nullable(2) .^ Nullable(4)      |> isnullableof(16)
@test Nullable(2) .^ Nullable{Int}()  |> isnull_typed(Int)

# big broadcast (slow)
@test Nullable(1) .+ Nullable(1) .+ Nullable(1) .+ Nullable(1) .+ Nullable(1) .+
    Nullable(1) |> isnullableof(6)
@test Nullable(1) .+ Nullable(1) .+ Nullable(1) .+ Nullable{Int}() .+
    Nullable(1) .+ Nullable(1) |> isnull_typed(Int)

# very slow but it should work
us = map(Nullable, 1:20)
@test broadcast(max, us...)                  |> isnullableof(20)
@test broadcast(max, us..., Nullable{Int}()) |> isnull_typed(Int)

# imperative style
s = 0
for x in Nullable(10)
    s += x
end
@test s == 10

s = 0
for x in Nullable{Int}()
    s += x
end
@test s == 0

end
