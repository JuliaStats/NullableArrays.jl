using NullableArrays
using NullableArrays.BenchmarkUtils

srand(1)
M1 = rand(Bool, 5_000_000)
M2 = rand(Bool, 5_000_000, 2)
A1 = rand(5_000_000)
A2 = rand(Float64, 5_000_000, 2)
B1 = rand(Bool, 5_000_000)
B2 = rand(Bool, 5_000_000, 2)
C1 = rand(1:10, 5_000_000)
C2 = rand(Int, 5_000_000, 2)
L = Array(Float64, 5_000_000, 2)

U = NullableArray(Float64, 5_000_000, 2)
X1 = NullableArray(A1)
X2 = NullableArray(A2)
Y1 = NullableArray(A1, M1)
Y2 = NullableArray(A2, M2)
Z1 = NullableArray(B1)
Z2 = NullableArray(B2)
Q1 = NullableArray(C1)
Q2 = NullableArray(C2)
V1 = NullableArray(C1, M1)
V2 = NullableArray(C2, M2)

f(x, y) = x * y

Benchmarks.@benchmarkable(
    _broadcast!,
    begin
        func = f
        dest = U
        src1 = X1
        src2 = X2
    end,
    broadcast!(func, dest, src1, src2),
    nothing
)

function profile_broadcast!(n_samples, n_evals)
    samples = Benchmarks.Samples()
    env = Benchmarks.Environment()
    profile_broadcast!(broadcast_samples, n_samples, n_evals)

    pkg_dir = Pkg.dir("NullableArrays")
    writecsv(pkg_dir * "perfres/env.tsv", env)
    writecsv(pkg_dir * "perfres/broadcast3.csv", samples, env)
end

profilers = Any[]
i = 1
for op              in  (.+, .-, .*, ./, .%, .^, .==, .!=, .<, .>, .<=, .>=,),
    (src1, src2)    in  ((X1, X2), (Y1, Y2)),
    (symb1, symb2)  in  ((:X1, :X2), (:Y1, :Y2)),
    missing         in  ("zero", "half"),
    skip            in  (false, true)

    # loop body
    e_test_fn = Expr(:call, symbol(op), symb1, symb2)
    profiler_name = (symbol("_$i"))
    e_push = :( push!(profilers, ($profiler_name, string($op), $missing, string($skip))) )
    @eval begin
        Benchmarks.@benchmarkable(
            $profiler_name,
            nothing,
            $e_test_fn,
            nothing
        )
        $e_push
    end
    i += 1
end

function profile(n_samples, n_evals)
    pkg_dir = Pkg.dir("NullableArrays")
    pkg_dir_res_env = joinpath(pkg_dir, "res/env.tsv")
    pkg_dir_res_broadcast = joinpath(pkg_dir, "res/broadcast.csv")
    # make sure Benchmarks.Environment() captures SHA1 of current
    # NullableArrays commit
    _pwd = pwd()
    cd(pkg_dir)
    env = Benchmarks.Environment()
    cd(_pwd)
    # write Environment info and profiling results to file
    writecsv(pkg_dir_res_env, env, true, ',', false)
    for i in eachindex(profilers)
        samples = Benchmarks.Samples()
        profilers[i][1](samples, n_samples, n_evals)
        BenchmarkUtils.writecsv(pkg_dir_res_broadcast, profilers[i], samples,
                                env, true, ',', false)
    end
end
