module Benchmark
    include("queens.jl")
    include("sudoku.jl")
    include("colorability.jl")
    include("all_interval_series.jl")
    include("graceful_graphs.jl")
    export queens_cp, queens_lp, sudoku2D, colorability_cp, allIntervalSeries, gracefullGraph
end

