include("../benchmark/queens.jl")
include("../solver/solver.jl")

module TestQueens

    using ..Benchmark: queens_cp, queens_lp
    using ..Solver
    
    N = 8
    #fourQueensCP = queens_cp(N) 
    fourQueensLP = queens_lp(N)

    # TODO : find why 'nothing' is being printed at the end of the string representation of an Problem
    #= println("fourQueensCP, ", fourQueensCP)
    println("\nnumber of constraints: ", length(fourQueensCP.constraints))
    println("") =#
    println("fourQueensLP, ", fourQueensLP)
    println("\nnumber of constraints: ", length(fourQueensLP.constraints))

    println("\nLet's solve the "*string(N)*"-queens problem")

    status, sol_time, sizeTree = solve(fourQueensLP, Inf, true, false, false, true)         # applyBacktrack, applyMACR, applyFC, applyMAC
    println("status: ", status)
    println("time: ", sol_time)
    println("size of the tree: ", sizeTree)

    #= for var in values(fourQueensLP.variables)
        println(string(var)*": "*string(var.value))
    end =#

end