#include("model/binary_operands.jl")
#include("model/lp_operands.jl")
#include("model/operations.jl")
include("model/instance.jl")
using .Instance

### TESTS ####

## Testing model/basic.jl ##

if false
    
    x = Variable("x", collect(Float64, 0:5), undef)
    y = Variable("y", collect(0:5), undef)

    c1 = BConstraint(["x", "y"], [(0,0), (0,1), (1,0)])
    c2 = BConstraint(["x", "y"], [(1,0),(2,1)])

    instance1 = Instance_BCSP(collect([x,y]),collect([c1,c2]))
    print("\nINSTANCE BUILT BEFORE:\n")
    print(instance1)

    print("\nINSTANCE BUILT AFTER:\n")
    instance2 = Instance_BCSP()
    print(instance2)

end

## Testing model/extended.jl

if true

    x = Variable("x", collect(Float64, 0:5), undef)
    y = Variable("y", collect(0:5), undef)
    expr= 2*x + 3*y
    println("expr: ", expr)
    expr= 2*x - 3*y
    println("expr: ", expr)
    expr = -expr - 1
    println("expr: ", expr)
    constraint = expr == -1
    println("constraint: ", constraint)
    feasPoints = makeExplicit(constraint)
    println("\nFeasible points:\n", feasPoints)

    instance1 = Instance_BCSP([x,y])
    print("\nInstance before adding the lp constraint:\n")
    print(instance1)
    print("\n\nInstance after adding the lp constraint:\n")
    addConstraint(instance1, constraint)
    print(instance1)
end