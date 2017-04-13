module TestUtils
    using StatsBase
    using Base.Test
    using NullableArrays

    @testset "describe" begin
        io = IOBuffer()
        describe(io, NullableArray(1:10))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Mean:           5.500000
                                   Minimum:        1.000000
                                   1st Quartile:   3.250000
                                   Median:         5.500000
                                   3rd Quartile:   7.750000
                                   Maximum:        10.000000
                                   Length:         10
                                   Type:           $Int
                                   Number Missing: 0
                                   % Missing:      0.000000
                                   """
        describe(io, NullableArray([1, Nullable()]))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Mean:           1.000000
                                   Minimum:        1.000000
                                   1st Quartile:   1.000000
                                   Median:         1.000000
                                   3rd Quartile:   1.000000
                                   Maximum:        1.000000
                                   Length:         1
                                   Type:           $Int
                                   Number Missing: 1
                                   % Missing:      50.000000
                                   """
        describe(io, NullableArray(["s"]))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Length:         1
                                   Type:           Nullable{String}
                                   Number Unique:  1
                                   Number Missing: 0
                                   % Missing:      0.000000
                                   """
        describe(io, NullableArray(["s", Nullable()]))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Length:         2
                                   Type:           Nullable{String}
                                   Number Unique:  2
                                   Number Missing: 1
                                   % Missing:      50.000000
                                   """
        describe(io, ["s", Nullable()])
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Length:         2
                                   Type:           Nullable{String}
                                   Number Unique:  2
                                   Number Missing: 1
                                   % Missing:      50.000000
                                   """
        describe(io, [1, Nullable()])
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Mean:           1.000000
                                   Minimum:        1.000000
                                   1st Quartile:   1.000000
                                   Median:         1.000000
                                   3rd Quartile:   1.000000
                                   Maximum:        1.000000
                                   Length:         1
                                   Type:           $Int
                                   Number Missing: 1
                                   % Missing:      50.000000
                                   """
        describe(io, NullableArray{Any}(5))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Length:         5
                                   Type:           Nullable{Any}
                                   Number Unique:  1
                                   Number Missing: 5
                                   % Missing:      100.000000
                                   """
        describe(io, NullableArray{Float64}(5))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Type:           Nullable{Float64}
                                   Number Missing: 5
                                   % Missing:      100.000000
                                   """
        describe(io, fill(Nullable{String}(), 5))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Length:         5
                                   Type:           Nullable{String}
                                   Number Unique:  1
                                   Number Missing: 5
                                   % Missing:      100.000000
                                   """
        describe(io, fill(Nullable{Float64}(), 5))
        @test String(take!(io)) == """
                                   Summary Stats:
                                   Type:           Nullable{Float64}
                                   Number Missing: 5
                                   % Missing:      100.000000
                                   """
    end
end
