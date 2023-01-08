include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestInterval

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: allIntervalSeriesBinary, allIntervalSeries
    using ..Wrapper: all_different
    using Dates

    println("\nLet's test the backtrack algorithm on the interval series")
    
    instance = allIntervalSeriesBinary(5)

    #print(instance)
    found_sol, solTime, sizeTree = solve(instance, Inf, true, false, true, false)         # applyBacktrack, applyMACR, applyFC, applyMAC
    #found_sol, sol_time = solve(instance)
    println("found a solution? ", found_sol)
    println("time elapsed: ", solTime)
    println("size of the tree: ", sizeTree)

    for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end

end