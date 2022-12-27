include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestInterval

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: allIntervalSeriesBinary
    using ..Wrapper: all_different

    println("\nLet's test the backtrack algorithm on the interval series")
    
    instance = allIntervalSeriesBinary(5)

    print(instance)
    found_sol = backjumping(instance)
    # found_sol = backtrack(instance)
    println("found a solution? ", found_sol)

    for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end

end