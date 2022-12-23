include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestColoring

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: queens_cp, colorability_cp
    using ..Wrapper: all_different

    path = "..\\..\\External instances\\instances_coloring\\random-10.col"
    instance = colorability_cp(path)

    print(instance)

    #= ## Backtrack ##

    println("\nLet's test the backtrack algorithm on the coloring")
    
    found_sol = backtrack(instance)
    println("found a solution? ", found_sol)

    for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end =#

end