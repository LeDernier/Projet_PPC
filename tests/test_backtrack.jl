include("../model/instance.jl")
include("../solver/backtrack.jl")
#include("../benchmark/queens.jl")

using .Instance: diff, Variable

println("Let's test the wrapper\n")
# alldiff(instance)
x = Variable("x", collect(Float64, 0:5), undef)
y = Variable("y", collect(0:5), undef)
instance = Instance_BCSP([x, y])
addConstraints(instance, diff(x, y, 1, 1, 2))
print(instance)


println("Let's test the backtrack algorithm")

found_sol = backtrack(instance)
println("found a solution? ", found_sol)
print(instance)

z = Variable("z", collect(Float64, 0:5), undef)
t = Variable("t", collect(0:5), undef)

c3 = BConstraint("c3", ["z", "t"], [(0,0), (0,1), (1,0)])
c4 = BConstraint("c4", ["z", "t"], [(3,0),(2,1)])

instance2 = Instance_BCSP([z,t],[c3,c4])
print(instance2)

println()
println("Let's test the backtrack algorithm on the second instance")

found_sol = backtrack(instance2)
println("found a solution? ", found_sol)

#= println()        # TODO : fix the bugs of this block of code (problem with the imports)
println("Let's test the backtrack algorithm on the queens")
n=8
instance3 = queens_instance(n)
found_sol = backtrack(instance3)
println("found a solution? ", found_sol)

for var in values(instance3.variables)
    println(var)
end =#