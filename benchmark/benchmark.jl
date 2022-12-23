module Benchmark
    include("queens.jl")
    include("sudoku.jl")
    include("colorability.jl")
    export queens_cp, queens_lp, sudoku2D, colorability_cp, getEdges, getMaxColors
end

