using ..Instance: Problem, getVariable, _varIDType, _varValueType

function backtrack(instance::Problem, init_time::Real=0.0, maxTime::Real=Inf, depth=0,
    applyMACR=true, applyFC=true, applyMAC=false)::Bool
    #= var = instance.objective
    i_min = var.index_domain_lower
    i_max = var.index_domain
    println(string(var)*": "*string(var.value), ", (i_min,i_max): (", i_min, ", ", i_max, ")")
    println("virtual_domain: ", var.domain[i_min:i_max]) =#

    ## MAC at the root
    if applyMACR
        isInconsistent = AC4(instance)
        if isInconsistent
            return false
        end
    end

    ## actual backtrack
    vars_ids = collect(keys(instance.variables))
    #sort!(var_names, by = x -> instance.variables[x].index_domain - instance.variables[x].index_domain_lower)
    index_undefined_var = 1
    return actualBacktrack(instance, vars_ids, index_undefined_var, init_time,
                            maxTime, depth, applyFC, applyMAC)
end

function actualBacktrack(instance::Problem, vars_ids::Vector{_varIDType}, index_undefined_var::Integer,
    init_time::Real=0.0, maxTime::Real=Inf, depth::Integer=0, 
    applyFC::Bool=true, applyMAC::Bool=false)::Bool

    # check if the delta_time <= maxTime in the solver
    if time() - init_time > maxTime
        return false
    end

    #= ## MAC arc-consistency
    isInconsistent = directional_arcconsistency(instance, false, true, false)
    if isInconsistent
        return false
    else
        isInconsistent = directional_arcconsistency(instance, true, true, false)
        if isInconsistent
            return false
        end
    end =#

    # MAC
    if applyFC && depth > 0
        isInconsistent = forward_checking(instance, vars_ids, index_undefined_var, true)
        if isInconsistent
            return false
        end
    else
        if applyMAC
            isInconsistent = AC4(instance)
            if isInconsistent
                return false
            end
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
    
    completed = index_undefined_var > length(vars_ids)

    if completed
        return true
    end

    undefined_var = getVariable(instance, vars_ids[index_undefined_var])
    if undefined_var.value != undef
        println("Iterating multiple times on the same variable: ", undefined_var.ID, ", with index: ", index_undefined_var)
        return false
    end

    
    #= completed = true
    undefined_var = undef
    domain_size = Inf
    for var in values(instance.variables)
        if var.value == undef
            completed = false
            _domain_size = length(var.domain)
            if _domain_size < domain_size    
            #_virtual_domain_size = var.index_domain - var.index_domain_lower
            #if _virtual_domain_size < domain_size       
                undefined_var = var
                domain_size = _domain_size
                #domain_size = _virtual_domain_size
            end
        end
    end =#

    # here, undefined_var is the variable with the smallest domain.
    # we could improve that in the future
    # for instance with the variables with the most constraints

    # -> forward checking or maintain-arc-consistency or in between both
    # idea: maintain-arc-consistency only at the root and then forward checking here

    # keep track of the virtual domain
    _index_domain_lower = Dict(var.ID => var.index_domain_lower for var in values(instance.variables))
    _index_domain = Dict(var.ID => var.index_domain for var in values(instance.variables))
    #_domain = Dict(var.ID => var.domain for var in values(instance.variables))

    i_min = undefined_var.index_domain_lower
    i_max = undefined_var.index_domain
    idx_current = i_min
    for current_value in undefined_var.domain[i_min:i_max]

        undefined_var.value = current_value
        #= undefined_var.index_domain = idx_current
        undefined_var.index_domain_lower = idx_current =#
        if actualBacktrack(instance, vars_ids, index_undefined_var + 1, init_time, maxTime, depth+1)[1]
            return true
        end
        # restore the virtual domain
        for var in values(instance.variables)
            var.index_domain_lower = _index_domain_lower[var.ID]
            var.index_domain = _index_domain[var.ID]
            #var.domain = _domain[var.ID]
        end 
        idx_current += 1
    end

    undefined_var.value = undef

    return false
end

### ARC-CONSISTENCY ALGORTHMS ###

function directional_arcconsistency(instance::Problem, filterFirst=false, arc_consistency=true, forward_checking=true)
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
    count = Dict{Tuple{Integer, Integer}, Dict{Any, Integer}}()     # TODO: change Any type by something like: Union{Float64, <:Tuple}
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
            if arc_consistency && val_i == undef
                for val_i in var_i.domain[idx_i_min:idx_i_max]
                    # point = (val_1, val_2) in the order they appear in the constraint
                    if filterFirst
                        point = (val_j, val_i)
                    else
                        point = (val_i, val_j)
                    end

                    if point in constr.feasible_points
                        if !(val_j in keys(count[(idx_var[var_i.ID], idx_var[var_j.ID])]))
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
                
            else
                if forward_checking
                    ## forward checking : for val_i != undef, we remove all the val_j if (var_i,var_j) not in constr.feasible_points
                    # point = (val_1, val_2) in the order they appear in the constraint
                    if filterFirst
                        point = (val_j, val_i)
                    else
                        point = (val_i, val_j)
                    end
                    
                    # if val_j is not consistent, we remove it from the domain
                    if !(point in constr.feasible_points)
                        var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                        var_j.index_domain = var_j.index_domain - 1
                    end
                end
            end
            idx_val_j += 1
        end

        # the problem is inconsistent (return true) if the virtual domain of var_j is empty
        if var_j.index_domain < var_j.index_domain_lower
            return true
        end
    end

    return false
end



function forward_checking(instance::Problem, vars_ids::Vector{_varIDType}, 
        index_undefined_var::Integer,filterFirst=false)
    """
        A forward checking algorithm.

        Parameters
            - instance: instance of a problem.
            - filterFirst: for a constraint C_{x,y}, if true, the domain of the variable
             x is filtered based on y. Reciprocally, if false, the domain of the variable
             y is filtered based on x.
    """

    list_constraints = values(instance.constraints)
    last_inst_var_id = vars_ids[index_undefined_var-1]      # last instantiated var

    for constr in list_constraints
        constr_vars = [instance.variables[id_var] for id_var in constr.varsIDs]
        
        ## defining var_i as the last instantiated variable
        if constr_vars[2].ID == last_inst_var_id 
            var_i = constr_vars[2]
            var_j = constr_vars[1]
        else
            if constr_vars[1].ID == last_inst_var_id 
                var_i = constr_vars[1]
                var_j = constr_vars[2]
            else
                break
            end
        end

        val_i = var_i.value
        val_j = var_j.value

        # only filter uninstantiated variables
        if val_j != undef

            idx_j_min = var_j.index_domain_lower
            idx_j_max = var_j.index_domain
            
            idx_val_j = idx_j_min           # keep track of the index of the value of j in its domain
            for val_j in var_j.domain[idx_j_min:idx_j_max]
                # rearrange values according to the constraint
                if constr_vars[2].ID == last_inst_var_id 
                    point = (val_j, val_i)
                else
                    point = (val_i, val_j)
                end
                
                # if val_j is not consistent, we remove it from the domain
                if !(point in constr.feasible_points)
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1
                end
                idx_val_j += 1
            end

            # the problem is inconsistent (return true) if the virtual domain of var_j is empty
            if var_j.index_domain < var_j.index_domain_lower
                return true
            end    
        end
    end

    return false
end

### PREFILTERING ALGORTHMS ###

function initAC4(instance::Problem, 
    count::Dict{Tuple{_varIDType, _varIDType, _varValueType}, Integer},
    removed::Vector{Tuple{_varIDType, _varValueType}},
    consistentValues::Dict{Tuple{_varIDType, _varValueType}, Vector{Tuple{_varIDType, _varValueType}}},
    filterFirst=false)          # TODO : this parameter is not necessary in AC4
    
    """
        A version of the initAC4 algorithm.

        Parameters
            - instance: instance of a problem.
            - filterFirst: for a constraint C_{x,y}, if true, the domain of the variable
             x is filtered based on the domain of y. Reciprocally, if false, the domain 
             of the variable y is filtered based on the domain of x.
            - count[(x,y,b)] := for two variables x,y, it counts the number of values of x in D_x that are consistent with <y,b>
            - removed : it contains the pairs (y,b) removed by arc-inconsistency.
            - consistentValues[(x,a)] := it contains the pairs (y,b) so that there exists at least 
    """

    list_constraints = values(instance.constraints)
    
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
        
        idx_val_j = idx_j_min           # keep track of the index of the value of j in its domain
        for val_j in var_j.domain[idx_j_min:idx_j_max]
            if val_i == undef
                support_j_size = 0      # size of the support of val_j
                for val_i in var_i.domain[idx_i_min:idx_i_max]
                    # point = (val_1, val_2) in the order they appear in the constraint
                    if filterFirst
                        point = (val_j, val_i)
                    else
                        point = (val_i, val_j)
                    end

                    if point in constr.feasible_points
                        support_j_size += 1
                        push!(consistentValues[(var_i.ID, val_i)], (var_j.ID, val_j))       # WARNING : repeated values if multiple constraints on the same pair of variables
                    end
                end

                count[(var_i.ID, var_j.ID, val_j)] = support_j_size
                
                # if val_j is not consistent, we remove it from the domain
                if count[(var_i.ID, var_j.ID, val_j)] == 0
                    # delete virtually val_j from var_j.domain
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1

                    # record the removed pair (var_j.ID, val_j)
                    push!(removed, (var_j.ID, val_j))
                end
            end
            idx_val_j += 1
        end

        # the problem is inconsistent (return true) if the virtual domain of var_j is empty
        if var_j.index_domain < var_j.index_domain_lower
            return true
        end
    end

    return false

end

function AC4(instance::Problem)

    """
        A version of the main AC4 algorithm.

        Parameters
            - instance: instance of a problem.
    """

    removed = Vector{Tuple{_varIDType, _varValueType}}()                                           # Q / elements removed by arc-consistency; of the form (varX.ID,valX)
     
    consistentValues = Dict{Tuple{_varIDType, _varValueType}, Vector{Tuple{_varIDType, _varValueType}}}()   # S / for <y,b>, it stores the list of <x,a> such that there exists a constraint C_{x,y} such that (a,b) is feasible 
    # init conistentValues
    for var_i in values(instance.variables)
        for val_i in var_i.domain
            consistentValues[(var_i.ID, val_i)] = Vector{Tuple{_varIDType, _varValueType}}()
        end
    end

    # TODO: handle the duplicate elements due to multiple constraints on the same pair of variables

    count = Dict{Tuple{_varIDType, _varIDType, _varValueType}, Integer}()                       # count(x,y,b)
    
    ## initial filter
    isInconsistent = initAC4(instance, count, removed, consistentValues)
    if isInconsistent
        return isInconsistent
    end

    ## propagation
    while length(removed) > 0
        (var_i_ID, val_i) = popfirst!(removed)
        var_i = getVariable(instance, var_i_ID)
        
        if (var_i.ID, val_i) in keys(consistentValues)
            for (var_j_ID, val_j) in consistentValues[(var_i.ID, val_i)]
                var_j = getVariable(instance, var_j_ID)
                idx_j_min = var_j.index_domain_lower
                idx_j_max = var_j.index_domain
                count[(var_i.ID, var_j.ID, val_j)] -= 1
                if count[(var_i.ID, var_j.ID, val_j)] == 0 && val_j in var_j.domain
                    # delete virtually val_j from var_j.domain
                    idx_j_max = findfirst(isequal(val_j), var_j.domain[idx_j_min:idx_j_max])
                    idx_j_max += idx_j_min - 1      # corrected since var_j.domain was filtered
                    var_j.domain[idx_j_max], var_j.domain[idx_val_j] = var_j.domain[idx_val_j], var_j.domain[idx_j_max]
                    var_j.index_domain = var_j.index_domain - 1
                
                    # record the removed pair (var_j.ID, val_j)
                    push!(removed, (var_j.ID, val_j))

                    # the problem is inconsistent (return true) if the virtual domain of var_j is empty
                    if var_j.index_domain < var_j.index_domain_lower
                        return true
                    end
                end
            end
        end
    end

    return false
end

### SORTING ALGORTHMS ON VARIABLES ###