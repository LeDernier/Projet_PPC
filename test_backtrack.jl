include("backtrack.jl")
include("wrapper.jl")

println("Let's test the wrapper")
# alldiff(instance)
diff(x, y, 1, 1, 2, instance)
print_instance(instance)


println("Let's test the backtrack algorithm")

found_sol = backtrack(instance)
println("found a solution? ", found_sol)
print_instance(instance)

z = Variable("z", 1, collect(Float64, 0:5), undef)
t = Variable("t", 2, collect(0:5), undef)

c3 = BConstraint("c3", ("z", "t"), (1, 2), collect([(0,0), (0,1), (1,0)]))
c4 = BConstraint("c4", ("z", "t"), (1, 2), collect([(3,0),(2,1)]))

instance2 = Instance_BCSP(collect([z,t]),collect([c3,c4]))
print_instance(instance2)

println()
println("Let's test the backtrack algorithm on the second instance")

found_sol = backtrack(instance2)
println("found a solution? ", found_sol)

println()
println("Let's test the backtrack algorithm on the queens")
n=8
instance3 = queens_instance(n)
found_sol = backtrack(instance3)
println("found a solution? ", found_sol)

for var in instance3.variables
    println(var)
end