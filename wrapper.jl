
module Wrapper

    export alldiff

    include("model/basic.jl")
    using .Model

    function alldiff(variables::Vector{Variable})::BConstraint
        """
            Returns a set of (binary) constraint with all the values of the variables v1 and v2 such that v1 != v2.
        """
        nbVars = length(variables)              # number of variables
        for i in 1:nbVars-1
            var1 = variables[i]
            for j in i+1:nbVars
                var2 = variables[j]
                values = [(x, y) for x in var1.domain for y in var2.domain if x != y]
                c = BConstraint("diff_" * var1.name * "_" * var2.name, collect([var1, var2]), values)
                push!(instance.constraints, c) #do we change instance out of the function here?
            end
        end
    end

    function weightedSum(variables::Vector{Variable}, weights::Vector{Real}, condition::Function)::BConstraint
        """
            Returns a (binary) constraints with the values such that the scalar/dot product between 'variables'\
            and 'weights' satisfy the 'condition'.
        """
        
        checkBinary(variables)


    end

    function checkBinary(variables::Vector{Variable})
        """
            Checks if the number of variables is two (when creating binary constraints).
        """

        nbVar = length(variables)
        if nbVar != 2
            error("alldiff constraint is only defined for binary constraints (2 variables).")
        end
    end
end