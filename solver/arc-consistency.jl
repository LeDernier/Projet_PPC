using ..Instance: Problem, getVariable, _varIDType, _varValueType

### ARC-CONSISTENCY ALGORTHMS ###

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
            continue
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