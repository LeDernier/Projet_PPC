include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/benchmark.jl")

module TestSudoku

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: queens_cp, sudoku2D
    using ..Wrapper: all_different

    ## Sudoku ##

    println("\nLet's test the backtrack algorithm on the sudoku")
    preAffectations = [ 
    [1 1 8];
    [1 3 4];
    [1 7 2];
    [1 9 9];
    [2 3 9]; 
    [2 7 1];
    [3 1 1];   
    [3 4 3];
    [3 6 2];
    [3 9 7];
    [4 2 5];
    [4 4 1];
    [4 6 4];
    [4 8 8];
    [5 5 3];
    [6 2 1];
    [6 4 7];
    [6 6 9];
    [6 8 2];
    [7 1 5];
    [7 4 4];
    [7 6 3];
    [7 9 8];
    [8 3 3];
    [8 7 4];
    [9 1 4];
    [9 3 6];
    [9 7 3];
    [9 9 1]]
    dim = 3

    #= preAffectations = [
        [1 1 1];
        [3 1 2];
    ] =#
    dim = 3                                       # TODO : improve the performance for dim=3
    instance4 = sudoku2D(preAffectations, dim)

    print(instance4)
    println("\nLet's solve the sudoku problem.")
    found_sol = solve(instance4)
    println("found a solution? ", found_sol)

    for var in values(instance4.variables)
        println(string(var)*": "*string(var.value))
    end

end