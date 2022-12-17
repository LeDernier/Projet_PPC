"""
    Algorithms.
"""

module Solver

    #include("../model/instance.jl")                    # this should only be included in the main file
    #include("constants.jl")
    using ..Instance: Problem, getVariable        # .. because the include(..model/instance.jl) should be done in the file that includes this file
    

    export backtrack

    #= function solve(instance::Problem)
        resolveOk = false
        solutionStatus = CspSolutionNoSolutionFound
        solutionTime = 0.0

        diff_time =  time()
        resolveOk = backtrack(instance)
        diff_time = time() - diff_time
        if resolveOk
            solutionStatus = CspSolutionSolutionFound
            status = CspStatusFeasible
        end

    end =#


    function backtrack(instance::Problem)::Bool

        # check that all constraints are respected
        for c in instance.constraints
            id1 = c.varsIDs[1]
            id2 = c.varsIDs[2]
            var1 = getVariable(instance, id1).value
            var2 = getVariable(instance, id2).value
            if var1 != undef && var2 != undef
                found_feasible_point = false
                for values in c.feasible_points
                    if var1 == values[1] && var2 == values[2]
                        found_feasible_point = true
                        break
                    end
                end
                if !found_feasible_point
                    return false
                end
            end
        end

        # check that some variables are undefined
        completed = true
        undefined_var = undef
        domain_size = 10000000
        for var in values(instance.variables)
            if var.value == undef
                completed = false
                if length(var.domain) < domain_size
                    undefined_var = var
                end
            end
        end

        if completed
            return true
        end

        # here, undefined_var is the variable with the smallest domain.
        # we could improve that in the future
        # for instance with the variables with the most constraints

        # TODO : add arc consistency 
        # -> forward checking or maintain-arc-consistency or in between both
        # idea: maintain-arc-consistency only at the root and then forward checking here

        i_max = undefined_var.index_domain
        for current_value in undefined_var.domain[1:i_max]
            undefined_var.value = current_value
            if backtrack(instance)[1]
                return true
            end
            undefined_var.value = undef
        end

        return false
    end

end