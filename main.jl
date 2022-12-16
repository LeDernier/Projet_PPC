## A TOY EXAMPLE: how to import the modules 

include("model/instance.jl")            # the code of the optimisation model should be imported whenever needed for this module or imported modules
#include("solver/algorithmX.jl")                  # the code of the solver should be imported (it uses model/instance)
#include("../benchmark/problemY.jl")            # the code of the instance should be imported (it uses model/instance)

module Main

    using ..Instance
    #using ..AlgorithmX
    #using ..ProblemY

end