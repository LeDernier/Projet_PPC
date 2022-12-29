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

function directional_arcconsistency(instance::Problem, order_constraints=identity)
    """
        A lazy version of the initAC4 algorithm with forward ahead.

        Parameters
            - instance: instance of a problem.
            - order_constraints: an order to be applied to values(instance.constraints).
    """

    num_vars = length(instance.variables)
    list_vars = collect(values(instance.variables))
    list_constraints = order_constraints(values(instance.constraints))
    # count(x,y,b) := for two variables x,y, it counts the number of values of x in D_x that are consistent with <y,b>
    count = Dict{Tuple{Integer, Integer}, Dict{Float64, Integer}}()
    idx_var = Dict(list_vars[i].ID => i for i in 1:num_vars)
    
    for constr in list_constraints
        
        # variable 1 or i
        var_i = list_vars[1]
        idx_i_min = var_i.index_domain_lower
        idx_i_max = var_i.index_domain
        val_i = var_i.value
        
        # variable 2 or j
        var_j = list_vars[2]
        idx_j_min = var_j.index_domain_lower
        idx_j_max = var_j.index_domain
        
        # only apply arc-consistency to non-fixed variables
        if var_j.value != undef
            break
        end
        
        idx_val_j = idx_j_min           # keep track of the index of the value of j in its domain
        for val_j in var_j.domain[idx_j_min:idx_j_max]
            if val_i == undef
                # forward checking : we remove all the val_j if (var_i,var_j) not in constr.feasible_points
                for val_i in var_i.domain[idx_i_min:idx_i_max]
                    if (val_i, val_j) in constr.feasible_points
                        # add the (x,y) key to the dictionary if it does not exist
                        if !((idx_var[var_i.ID], idx_var[var_j.ID]) in keys(count))
                            count[(idx_var[var_i.ID], idx_var[var_j.ID])] = Dict()
                        end

                        if val_j in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])])
                            # increase the value associated to the key val_j
                            count[(idx_var[var_i.ID], idx_var[var_j.ID])][val_j] += 1
                        else
                            # add the val_j key to the dictionary if it does not exist
                            count[(idx_var[var_i.ID], idx_var[var_j.ID])][val_j] = 1
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
                # if val_j is not consistent, we remove it from the domain
                if !((val_i, val_j) in constr.feasible_points)
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1
                end
                idx_val_j += 1
            end
        end
    end

    # return false if there are variables with no consistent values
    for var in values(instance.variables)
        if var.index_domain == 0 || var.index_domain < var.index_domain_lower
            #println("The variable ", var.ID, " is inconsistent: index_domain_u=", var.index_domain, ", index_domain_l=", var.index_domain_lower)
            return true
        end
    end

    return false
end

### PREFILTERING ALGORTHMS ###

function getRootSuffixIDMap(instance::Problem)
    """ TODO: DEPRECATED: Remove if it continues to be slow
        Returns a dictionary where there is a key for each pair of variables.
        Keys are strings of the form:
            key = bc_idVar1_idVar2
        and the values are the IDs of the constraints if the ID starts with the key:
            value = [bc_idVar1_idVar2_1, bc_idVar1_idVar2_2,...]
    """
    dict_pair_constr = Dict{String, Vector{String}}()
    for constr in values(instance.constraints)
        ID_splitted = split(constr.ID,"_")
        ID_root = join(ID_splitted[1:3], "_")
        
        ID_splitted[2], ID_splitted[3] = ID_splitted[3], ID_splitted[2]
        ID_root_rev = join(ID_splitted[1:3], "_")
        if ID_root in keys(dict_pair_constr)
            push!(dict_pair_constr[ID_root], constr.ID)
        else
            if ID_root_rev in keys(dict_pair_constr)
                # reverse the order of the variables in the constraint
                ID_suffix = ""
                if length(ID_splitted) >= 4
                    ID_suffix = "_"*join(ID_splitted[4:length(ID_splitted)], "_")
                end
                constr.ID = ID_root*ID_suffix
                constr.varsIDs = reverse(constr.varsIDs)
                constr.feasible_points = [(point[2],point[1]) for point in constr.feasible_points]
                push!(dict_pair_constr[ID_root], constr.ID)
            else
                dict_pair_constr[ID_root] = [constr.ID]
            end
        end
    end

    return dict_pair_constr
end

function intersect_constraints(instance::Problem)
    """ TODO: DEPRECATED. It is too slow.
        If there are more than one constraints on x,y, they are intersected.
    """

    ## group the constraints acting on the same pair of variables 
    dict_pair_constr = getRootSuffixIDMap(instance)

    ## intersect the constraints acting on the same pair of variables
    for ids_bConstr in values(dict_pair_constr)
        if length(ids_bConstr) >= 2
            constr_1 = instance.constraints[ids_bConstr[1]]
            numb_ids = length(ids_bConstr)
            for i in 2:numb_ids
                constr_i = instance.constraints[ids_bConstr[i]]
                filter!(e -> e in constr_i.feasible_points, constr_1.feasible_points)
                delete!(instance.constraints, constr_i.ID)
            end
        end
    end
end

### SORTING ALGORTHMS ON VARIABLES ###