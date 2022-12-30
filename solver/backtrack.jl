using ..Instance: Problem, getVariable

function backtrack(instance::Problem, init_time::Real=0.0, maxTime::Real=Inf)::Bool

    # check if the delta_time <= maxTime in the solver
    if time() - init_time > maxTime
        return false
    end

    # arc-consistency
    isInconsistent = directional_arcconsistency(instance)
    if isInconsistent
        return false
    else
        isInconsistent = directional_arcconsistency(instance, true)
        if isInconsistent
            return false
        end
    end

    # check that all constraints are respected
    for c in values(instance.constraints)
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
    domain_size = Inf
    for var in values(instance.variables)
        if var.value == undef
            completed = false
            if length(var.domain) < domain_size
                undefined_var = var
                domain_size = length(var.domain)
            end
        end
    end

    if completed
        return true
    end

    # here, undefined_var is the variable with the smallest domain.
    # we could improve that in the future
    # for instance with the variables with the most constraints

    # -> forward checking or maintain-arc-consistency or in between both
    # idea: maintain-arc-consistency only at the root and then forward checking here

    i_min = undefined_var.index_domain_lower
    i_max = undefined_var.index_domain
    for current_value in undefined_var.domain[i_min:i_max]
        undefined_var.value = current_value
        push!(instance.variables_instantiated, undefined_var)
        
        # keep track of the virtual domain
        index_domain_lower = Dict(var.ID => var.index_domain_lower for var in values(instance.variables))
        index_domain = Dict(var.ID => var.index_domain for var in values(instance.variables))
        if backtrack(instance, init_time, maxTime)[1]
            return true
        end
        # restore the virtual domain
        for var in values(instance.variables)
            var.index_domain = index_domain[var.ID]
            var.index_domain_lower = index_domain_lower[var.ID]
        end 

        # restore the undef value of the variable if there is not a consistent value
        undefined_var.value = undef
    end

    return false
end

### ARC-CONSISTENCY ALGORTHMS ###

function directional_arcconsistency(instance::Problem, filterFirst=false)
    """
        A lazy version of the initAC4 algorithm with forward checking.

        Parameters
            - instance: instance of a problem.
            - filterFirst: for a constraint C_{x,y}, if true, the domain of the variable
             x is filtered based on y. Reciprocally, if false, the domain of the variable
             y is filtered based on x.
    """

    num_vars = length(instance.variables)
    list_vars = collect(values(instance.variables))
    list_constraints = values(instance.constraints)
    # count(x,y,b) := for two variables x,y, it counts the number of values of x in D_x that are consistent with <y,b>
    count = Dict{Tuple{Integer, Integer}, Dict{Float64, Integer}}()
    idx_var = Dict(list_vars[i].ID => i for i in 1:num_vars)
    
    for constr in list_constraints
        # variables
        constr_vars = [instance.variables[id_var] for id_var in constr.varsIDs]
        if filterFirst
            var_i = constr_vars[2]
            var_j = constr_vars[1]
        else
            var_i = constr_vars[1]
            var_j = constr_vars[2]
        end
        
        # variable 1 or i
        idx_i_min = var_i.index_domain_lower
        idx_i_max = var_i.index_domain
        val_i = var_i.value
        
        # variable 2 or 
        idx_j_min = var_j.index_domain_lower
        idx_j_max = var_j.index_domain
        
        # only apply arc-consistency to non-fixed variables
        if var_j.value != undef
            break
        end

        count[(idx_var[var_i.ID], idx_var[var_j.ID])] = Dict()
        
        idx_val_j = idx_j_min           # keep track of the index of the value of j in its domain
        for val_j in var_j.domain[idx_j_min:idx_j_max]
            if val_i == undef
                # forward checking : we remove all the val_j if (var_i,var_j) not in constr.feasible_points
                for val_i in var_i.domain[idx_i_min:idx_i_max]
                      
                    if filterFirst
                        point = (val_j, val_i)
                    else
                        point = (val_i, val_j)
                    end

                    #inTheRange = point >= constr.min_feasible_point || point <= constr.max_feasible_point      # a faster way to check if the point is a feasible point
                    inTheRange = true
                    if inTheRange && point in constr.feasible_points

                        if val_j in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])])
                            # increase the value associated to the key val_j
                            count[(idx_var[var_i.ID], idx_var[var_j.ID])][val_j] += 1
                        else
                            # add the val_j key to the dictionary makes val_j a consistent value for var_j
                            count[(idx_var[var_i.ID], idx_var[var_j.ID])][val_j] = 1
                            break
                        end
                    end
                end
                
                # if val_j is not consistent, we remove it from the domain
                isInconsistentPair = !((idx_var[var_i.ID], idx_var[var_j.ID]) in keys(count))           # if <y,b> is inconsisent with <x,a> for all b
                isInconsistentValue = false
                if !isInconsistentPair
                    isInconsistentValue = !(val_j in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])]))   # if <y,b> is inconsisent with <x,a>
                end

                if isInconsistentValue
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1
                end
                idx_val_j += 1
            else

                if filterFirst
                    point = (val_j, val_i)
                else
                    point = (val_i, val_j)
                end

                # if val_j is not consistent, we remove it from the domain
                #inTheRange = point >= constr.min_feasible_point || point <= constr.max_feasible_point      # a faster way to check if the point is a feasible point
                inTheRange = true
                if !inTheRange || !((val_i, val_j) in constr.feasible_points)
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1
                end
                idx_val_j += 1
            end
        end

        # the problem is inconsistent (return true) if the virtual domain of var_j is empty
        if var_j.index_domain == 0 || var_j.index_domain < var_j.index_domain_lower
            #println("The variable ", var.ID, " is inconsistent: index_domain_u=", var.index_domain, ", index_domain_l=", var.index_domain_lower)
            return true
        end
    end

    return false
end


function directional_arcconsistency_2(instance::Problem, filterFirst=false)
    """
        A lazy version of the initAC4 algorithm with forward checking.

        Parameters
            - instance: instance of a problem.
            - filterFirst: for a constraint C_{x,y}, if true, the domain of the variable
            x is filtered based on y. Reciprocally, if false, the domain of the variable
            y is filtered based on x.
    """

    num_vars = length(instance.variables)
    list_vars = collect(values(instance.variables))
    list_constraints = values(instance.constraints)
    # count(x,y,b) := for two variables x,y, it counts the number of values of x in D_x that are consistent with <y,b>
    count = Dict{Tuple{Integer, Integer}, Dict{Float64, Integer}}()
    idx_var = Dict(list_vars[i].ID => i for i in 1:num_vars)
    var_idx = Dict(i => list_vars[i].ID for i in 1:num_vars)
    
    for constr in list_constraints
        constr_vars = [instance.variables[id_var] for id_var in constr.varsIDs]

        # variables
        var_i = constr_vars[1]
        var_j = constr_vars[2]
        
        # only apply arc-consistency to non-fixed variables
        if var_j.value != undef
            break
        end

        count[(idx_var[var_i.ID], idx_var[var_j.ID])] = Dict()
        count[(idx_var[var_j.ID], idx_var[var_i.ID])] = Dict()

        for point in constr.feasible_points
            # filter the domain of var_j based on the domain of var_i
            if !(last(point) in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])]))
                count[(idx_var[var_i.ID], idx_var[var_j.ID])][last(point)] = 1
            else
                count[(idx_var[var_i.ID], idx_var[var_j.ID])][last(point)] += 1
            end

            # filter the domain of var_i based on the domain of var_j
            if !(first(point) in keys(count[(idx_var[var_j.ID], idx_var[var_i.ID])]))
                count[(idx_var[var_j.ID], idx_var[var_i.ID])][first(point)] = 1
            else
                count[(idx_var[var_j.ID], idx_var[var_i.ID])][first(point)] =+ 1
            end
        end
    end

    for pair_vars in keys(count)
        # count(x,y,b) contains information to filter the domain of y
        # var_i or var_1
        id_var_i = var_idx[first(pair_vars)]
        var_i = instance.variables[id_var_i]
        
        # var_j or var_2
        id_var_j = var_idx[last(pair_vars)]
        var_j = instance.variables[id_var_j]

        # only apply arc-consistency to non-fixed variables
        if var_j.value != undef
            break
        end
        
        idx_j_min = var_j.index_domain_lower
        idx_j_max = var_j.index_domain

        idx_val_j = idx_j_min           # keep track of the index of the value of j in its domain
        for val_j in var_j.domain[idx_j_min:idx_j_max]
            # check consistency of val_j
            isInconsistentValue_j = !(val_j in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])]))   # if <y,b> is inconsisent with <x,a>
            if isInconsistentValue_j
                var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                var_j.index_domain = var_j.index_domain - 1
            end

            idx_val_j += 1
        end

        idx_i_min = var_i.index_domain_lower
        idx_i_max = var_i.index_domain

        idx_val_i = idx_i_min           # keep track of the index of the value of i in its domain
        for val_i in var_i.domain[idx_i_min:idx_i_max]
            # check consistency of val_i
            isInconsistentValue_i = !(val_i in keys(count[(idx_var[var_j.ID], idx_var[var_i.ID])]))   # if <y,b> is inconsisent with <x,a>
            if isInconsistentValue_i
                var_i.domain[idx_i_max], var_i.domain[idx_val_i] = var_i.domain[idx_val_i], var_i.domain[idx_i_max]
                var_i.index_domain = var_i.index_domain - 1
            end

            idx_val_i += 1
        end

        # the problem is inconsistent (return true) if the virtual domain of var_j is empty
        if var_j.index_domain == 0 || var_j.index_domain < var_j.index_domain_lower
            return true
        end

        # the problem is inconsistent (return true) if the virtual domain of var_i is empty
        if var_i.index_domain == 0 || var_i.index_domain < var_i.index_domain_lower
            return true
        end
    end

    return false
end

### PREFILTERING ALGORTHMS ###


### SORTING ALGORTHMS ON VARIABLES ###