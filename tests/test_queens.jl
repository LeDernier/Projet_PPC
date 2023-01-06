include("../benchmark/queens.jl")
include("../solver/solver.jl")

module TestQueens

    using ..Benchmark: queens_cp, queens_lp
    using ..Solver
    
    N = 20
    nQueensCP = queens_cp(N) 
    #fourQueensLP = queens_lp(N)

    # TODO : find why 'nothing' is being printed at the end of the string representation of an Problem
    #= println("nQueensCP, ", nQueensCP)
    println("\nnumber of constraints: ", length(nQueensCP.constraints))
    println("")
    println("fourQueensLP, ", fourQueensLP)
    println("\nnumber of constraints: ", length(fourQueensLP.constraints)) =#

    println("\nLet's solve the "*string(N)*"-queens problem")

    status, sol_time = solve(nQueensCP)
    println("status: ", status)
    println("time: ", sol_time, "\n")
    
    #= start = time() # in seconds
    found_sol = backjumping(nQueensCP, start, 350)
    time_elapsed = time() - start
    println("found a solution? ", found_sol)
    println("time elapsed:", time_elapsed) =#

    for var in values(nQueensCP.variables)
        println(string(var)*": "*string(var.value))
    end

end