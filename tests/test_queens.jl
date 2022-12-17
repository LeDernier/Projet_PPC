include("../benchmark/queens.jl")

module TestQueens

    using ..Benchmark: queens_cp, queens_lp

    fourQueensCP = queens_cp(3) 
    fourQueensLP = queens_lp(3)

    # TODO : find why 'nothing' is being printed at the end of the string representation of an Problem
    println("fourQueensCP, ", fourQueensCP)
    println("\nnumber of constraints: ", length(fourQueensCP.constraints))
    println("")
    println("fourQueensLP, ", fourQueensLP)
    println("\nnumber of constraints: ", length(fourQueensCP.constraints))

end