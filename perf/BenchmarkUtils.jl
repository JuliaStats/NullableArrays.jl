module BenchmarkUtils

using Benchmarks

function Base.writecsv(file::AbstractString, profiler, s::Benchmarks.Samples,
                  e::Benchmarks.Environment, append::Bool = false,
                  delim::Char = '\t', header::Bool = true)
    if append
        io = open(file, "a")
    else
        io = open(file, "w")
    end
    if header
        println(
            io,
            join(
                [
                    "env_uuid",
                    "op_name",
                    "n_nulls",
                    "skipnull",
                    "n_evals",
                    "elapsed_times",
                    "bytes_allocated",
                    "gc_times",
                    "num_allocations",
                ],
                delim
            )
        )
    end
    for i in 1:length(s.n_evals)
        println(
            io,
            join(
                [
                    string(e.uuid),
                    string(profiler[2]),
                    string(profiler[3]),
                    string(profiler[4]),
                    string(s.n_evals[i]),
                    string(s.elapsed_times[i]),
                    string(s.bytes_allocated[i]),
                    string(s.gc_times[i]),
                    string(s.num_allocations[i]),
                ],
                delim
            )
        )
    end
    close(io)
end

function Base.writecsv(filename::String, e::Benchmarks.Environment,
                       append::Bool = false, delim::Char = '\t',
                       header::Bool = true)
    if append
        io = open(filename, "a")
    else
        io = open(filename, "w")
    end
    if header
        println(
            io,
            join(
                [
                    "uuid",
                    "timestamp",
                    "julia_sha1",
                    "package_sha1",
                    "os",
                    "cpu_cores",
                    "arch",
                    "machine",
                    "use_blas64",
                    "word_size",
                ],
                delim
            )
        )
    end
    println(
        io,
        join(
            [
                e.uuid,
                e.timestamp,
                e.julia_sha1,
                get(e.package_sha1, "NULL"),
                e.os,
                string(e.cpu_cores),
                e.arch,
                e.machine,
                string(e.use_blas64),
                string(e.word_size),
            ],
            delim
        )
    )
    close(io)
end

end # module BenchmarkUtils
