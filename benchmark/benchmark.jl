module Benchmark
    
    include("queens.jl")
    include("sudoku.jl")

    export queens_cp, queens_lp, sudoku2D
end

