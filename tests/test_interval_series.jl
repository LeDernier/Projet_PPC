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
    
    instance = allIntervalSeriesBinary(7)

    print(instance)
    start = Dates.now()
    # found_sol = backjumping(instance)
    found_sol, sol_time = solve(instance)
    time_elapsed = Dates.now() - start
    println("found a solution? ", found_sol)
    println("time elapsed:", time_elapsed)

    for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end

end