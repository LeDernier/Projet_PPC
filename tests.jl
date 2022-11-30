include("model.jl")
using .Model

### TESTS ####

x = Variable("x", collect(Float64, 0:5), undef)
y = Variable("y", collect(0:5), undef)

c1 = BConstraint("c1", collect(["x", "y"]), collect([(0,0), (0,1), (1,0)]))
c2 = BConstraint("c2", collect(["x", "y"]), collect([(1,0),(2,1)]))

instance = Instance_BCSP(collect([x,y]),collect([c1,c2]))
print_instance(instance)