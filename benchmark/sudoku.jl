#include("../model/instance.jl")                # this should be included in the main file # TODO: remove
using ..Instance: Problem, Variable, addConstraint, addConstraints, BConstraint
using ..Wrapper: all_different

function sudoku2D(preAffectations::AbstractArray{<:Integer,3})
    """
        Parameters:
            - preAffectations: 3-dimensional arrays: (posX,posY,value at (posX,posY))
    """
    # create (declare) the variables
    grid = Array{Variable, 2}(undef, 3, 3)
    for i in 1:3
        for j in 1:3
            grid[i,j] = Variable(string(CartesianIndex(i,j)),1:9)
        end
    end

    # create the instance
    instance = Problem(variables)

    # add the constraints
    for p in eachindex(preAffectations)
        g
    end

    #= as_ints(a::AbstractArray{CartesianIndex{L}}) where L = reshape(reinterpret(Int, a), (L, size(a)...))
    for p in eachindex(preAffectations)
        i,j,val = as_ints(coord)
        grid[p] = Variable(string(p),[0,])
    end =#
end