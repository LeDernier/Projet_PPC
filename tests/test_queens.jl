include("../benchmark/queens.jl")

fourQueensCP = queens_instance(2) 
fourQueensLP = queens_lp(2)

# TODO : find why 'nothing' is being printed at the end of the string representation of an instance_BCSP
println("fourQueensCP, ", fourQueensCP)
println("\nnumber of constraints: ", length(fourQueensCP.constraints))
println("")
println("fourQueensLP, ", fourQueensLP)
println("\nnumber of constraints: ", length(fourQueensCP.constraints))