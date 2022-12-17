#include("../model/instance.jl")                # this should be included in the main file # TODO: remove
using ..Instance: Problem, Variable, addConstraint, addConstraints, getVariable
using ..Wrapper: all_different

function sudoku2D(preAffectations::AbstractArray, dim::Integer=3)
    """
        Parameters:
            - preAffectations: 3-dimensional arrays: (posX,posY,value at (posX,posY))
            - dim: number of columns/rows in the sub-grid
    """

    maxValue = dim*dim
    values = 1:maxValue
    ## create (declare) the variables
    grid = Array{Variable, 2}(undef, maxValue, maxValue)
    for i in 1:maxValue
        for j in 1:maxValue
            grid[i,j] = Variable(string((i,j)),collect(values))
        end
    end

    ## create the instance
    instance = Problem(grid)

    ## add the constraints
    # pre-assignation
    num_rows = size(preAffectations)[1]
    for row in 1:num_rows
        p = preAffectations[row,:]
        grid[p[1], p[2]] == p[3]
    end

    # sub-grid
    for i in 1:dim
        for j in 1:dim
            idVars_SubGrid = [(i1,j1) for i1 in (i-1)*dim+1:i*dim for j1 in (j-1)*dim+1:j*dim]
            vars_SubGrid = collect([getVariable(instance, string(id)) for id in idVars_SubGrid])
            addConstraints(instance, all_different(vars_SubGrid))
        end
    end

    # rows and columns
    for i in values
        idVars_SubGrid = [(i,j) for j in values]
        vars_SubGrid = collect([getVariable(instance, string(id)) for id in idVars_SubGrid])
        addConstraints(instance, all_different(vars_SubGrid))

        idVars_SubGrid = [(j,i) for j in values]
        vars_SubGrid = collect([getVariable(instance, string(id)) for id in idVars_SubGrid])
        addConstraints(instance, all_different(vars_SubGrid))
    end

    return instance
end