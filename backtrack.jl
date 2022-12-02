include("model.jl")

function backtrack(instance::Instance_BCSP)::Bool

    # check that all constraints are respected
    for c in instance.constraints
        idx1 = c.variable_indices[1]
        idx2 = c.variable_indices[2]
        var1 = instance.variables[idx1].value
        var2 = instance.variables[idx2].value
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
    for var in instance.variables
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
