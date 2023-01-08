using ..Instance: Problem, getVariable, _varIDType, _varValueType, size_domain

function backtrack(instance::Problem, init_time::Real=0.0, maxTime::Real=Inf,
    applyMACR=true, applyFC=true, applyMAC=false, sortVariablesBy::String="size_domain")
    """
        Parameters
            - instance:
            - init_time:
            - maxTime:
            - applyMACR: if true, apply Maintain-Arc-Consistency at the root node.
            - applyFC: if true, apply Forward-Checking.
            - applyMAC: if true, apply Maitain-Arc-Consistancy at each node of the tree.
            - sortVariablesBy: if 'size_domain', the variables are sorted by the domain size.
                if 'nb_constraints', the variables are sorted by the number of constraints in
                which they appear. Any other keyword will leave the variables unsorted.
    """

    ## MAC at the root
    if applyMACR
        isInconsistent = AC4(instance)
        if isInconsistent
            return false, sizeTree
        end
    end

    ## sort the variables
    vars_ids = collect(keys(instance.variables))
    if sortVariablesBy == "size_domain"
        sort!(vars_ids, by = x -> size_domain(instance.variables[x]))
    else
        if sortVariablesBy == "nb_constraints"
            sort!(vars_ids, by = x -> instance.variables[x].nb_constraints)
        end
    end

    ## call actual backtrack
    index_undefined_var = 1
    depthTree = 0
    sizeTree = 0
    isConsistent, sizeTree = actualBacktrack(instance, vars_ids, index_undefined_var, init_time,
    maxTime, depthTree, sizeTree, applyFC, applyMAC)
    return isConsistent, sizeTree
end

function actualBacktrack(instance::Problem, vars_ids::Vector{_varIDType}, index_undefined_var::Integer,
    init_time::Real=0.0, maxTime::Real=Inf, depthTree::Integer=0, sizeTree::Integer=0,
    applyFC::Bool=true, applyMAC::Bool=false)

    # check if the delta_time <= maxTime in the solver
    if time() - init_time > maxTime
        return false
    end

    # MAC
    if applyFC
        if depthTree > 0
            isInconsistent = forward_checking(instance, vars_ids, index_undefined_var, true)
            if isInconsistent
                return false, sizeTree
            end
        end
    else
        if applyMAC
            isInconsistent = AC4(instance)
            if isInconsistent
                return false, sizeTree
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
                return false, sizeTree
            end
        end
    end

    # check that some variables are undefined
    
    completed = index_undefined_var > length(vars_ids)

    if completed
        return true, sizeTree
    end

    undefined_var = getVariable(instance, vars_ids[index_undefined_var])

    # keep track of the virtual domain
    _index_domain_lower = Dict(var.ID => var.index_domain_lower for var in values(instance.variables))
    _index_domain = Dict(var.ID => var.index_domain for var in values(instance.variables))
    #_domain = Dict(var.ID => var.domain for var in values(instance.variables))

    i_min = undefined_var.index_domain_lower
    i_max = undefined_var.index_domain
    idx_current = i_min

    for current_value in reverse(undefined_var.domain[i_min:i_max])         # reversed to have the same order of values as in the backjumping algorithm

        undefined_var.value = current_value
        #= undefined_var.index_domain = idx_current
        undefined_var.index_domain_lower = idx_current =#
        isConsistent, sizeTree = actualBacktrack(instance, vars_ids, index_undefined_var + 1, init_time, maxTime, 
                                                depthTree + 1, sizeTree + 1, applyFC, applyMAC)
        if isConsistent
            return true, sizeTree
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

    return false, sizeTree
end