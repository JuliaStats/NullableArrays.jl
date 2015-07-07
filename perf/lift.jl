using NullableArrays

srand(1)
N = 5_000_000
f(x, y) = x * y
g(x, y) = x + y

X = NullableArray(rand(N))
Y = NullableArray(rand(N))

Xn = NullableArray(rand(N), rand(Bool, N))
Yn = NullableArray(rand(N), rand(Bool, N))

function tracedot(X, Y)
    res = Nullable(0.0)
    for i in 1:length(X)
         res += @^ f(X[i], Y[i]) Float64
    end
    return res
end

function test_no_nulls()
    tracedot(X, Y)
    # tracedot(X, Y)
    @time(tracedot(X, Y))
end

function test_half_nulls()
    tracedot(Xn, Yn)
    # tracedot(Xn, Yn)
    @time(tracedot(Xn, Yn))
end
