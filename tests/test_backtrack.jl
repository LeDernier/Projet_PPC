include("../model/instance.jl")         # it should be loaded whenever needed for this module or imported modules
include("../solver/solver.jl")
include("../model/wrapper.jl")
include("../benchmark/queens.jl")

module TestBacktrack

    using ..Instance: Variable, BConstraint, Problem, addConstraints, diff
    using ..Solver
    using ..Benchmark: queens_cp
    using ..Wrapper: different

    ### WRAPPER ###

    println("Let's test the wrapper\n")

    x = Variable("x", collect(Float64, 0:5), undef)
    y = Variable("y", collect(0:5), undef)
    instance = Problem([x, y])
    addConstraints(instance, different(x, y, 1, 1, 2))
    print(instance)

    ### BACKTRACK ###

    println("\nLet's test the backtrack algorithm")

    found_sol = backtrack(instance)
    println("found a solution? ", found_sol)
    print(instance)

    z = Variable("z", collect(Float64, 0:5), undef)
    t = Variable("t", collect(0:5), undef)

    c3 = BConstraint("c3", ["z", "t"], [(0,0), (0,1), (1,0)])
    c4 = BConstraint("c4", ["z", "t"], [(3,0),(2,1)])

    instance2 = Problem([z,t],[c3,c4])
    print(instance2)

    println()
    println("Let's test the backtrack algorithm on the second instance")

    found_sol = backtrack(instance2)
    println("found a solution? ", found_sol)
     
    println("\nLet's test the backtrack algorithm on the queens")
    n=8
    instance3 = queens_cp(n)
    found_sol = backtrack(instance3)
    println("found a solution? ", found_sol)

    for var in values(instance3.variables)
        println(var)
    end
end