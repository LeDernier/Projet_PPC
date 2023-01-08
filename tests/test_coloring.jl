include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestColoring

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver: solve, backtrack
    using ..Benchmark: queens_cp, colorability_cp, getEdges, getMaxColors
    using ..Wrapper: all_different

    path = "..\\..\\External instances\\instances_coloring\\random-10.col"
    edges, num_vertices, num_edges = getEdges(path)
    #max_colors_u = getMaxColors(edges, num_vertices)
    max_colors_u = num_vertices
    #max_colors_u = 8
    chrom_number_u = Variable("chromatic_number", collect(1:max_colors_u))
    instance = colorability_cp(edges,num_vertices, chrom_number_u)

    #print(instance)

    ## Solving by dichotomy ##

    println("\nLet's test the dichotomy algorithm on the coloring problem")
    
    status, sol_time, sizeTree = solve(instance, Inf, false, true, false, false)         # applyBacktrack, applyMACR, applyFC, applyMAC
    println("status: ", status)
    println("time: ", sol_time)
    println("size of the tree: ", sizeTree)
    println("objective: ", instance.objective.value)

    #= for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end =#
end