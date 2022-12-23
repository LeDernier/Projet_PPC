include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestColoring

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: queens_cp, colorability_cp, getEdges, getMaxColors
    using ..Wrapper: all_different

    path = "..\\..\\External instances\\instances_coloring\\random-10.col"
    edges, num_vertices, num_edges = getEdges(path)
    max_colors_u = getMaxColors(edges, num_vertices)
    chrom_number_u = Variable("chromatic_number", collect(1:max_colors_u), max_colors_u)
    instance = colorability_cp(edges,num_vertices, chrom_number_u)

    print(instance)

    #= ## Backtrack ##

    println("\nLet's test the backtrack algorithm on the coloring")
    
    found_sol = backtrack(instance)
    println("found a solution? ", found_sol)

    for var in values(instance.variables)
        println(string(var)*": "*string(var.value))
    end =#

end