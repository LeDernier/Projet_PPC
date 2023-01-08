
using ..Instance: Problem, Variable, getVariable, size_domain
using ..Solver: AC4

function consistant(instance::Problem, var_names::Array, k::Int, i::Int, a::Real)
    # check that all constraints are ok with the affectation
    # do we need to check a1, ... aK ? or is it the same with only current a ?
    x_name = var_names[i]
    for (key, c) in instance.constraints
        var1 = getVariable(instance, c.varsIDs[1])
        var2 = getVariable(instance, c.varsIDs[2])
        if var1.ID in var_names[1:k]
            # if var2.ID in var_names[1:k]
                # if !((var1.value, var2.value) in c.feasible_points)
                #     return false
                # end
            if var2.ID == x_name && !((var1.value, a) in c.feasible_points)
                return false
            # elseif !(var1.value in [p[1] for p in c.feasible_points])
            #     return false
            end
        elseif var2.ID in var_names[1:k]
            if var1.ID == x_name && !((a, var2.value) in c.feasible_points)
                return false
            # elseif !(var2.value in [p[2] for p in c.feasible_points])
            #     return false
            end
        elseif var1.ID == x_name && !(a in [p[1] for p in c.feasible_points])
            return false
        elseif var2.ID == x_name && !(a in [p[2] for p in c.feasible_points])
            return false
        end
    end
    return true
end


function selectValue1(instance::Problem, var_names::Array, D::Vector, i::Int, latest::Int)
    while length(D) > 0
        a = pop!(D)
        consist = true
        k = 1
        while k < i && consist
            if k > latest
                latest = k
            end
            if !consistant(instance, var_names, k, i, a)
                consist = false
            else
                k += 1
            end
        end
        if consist
            return a, latest
        end
    end
    if latest == i
        latest -= 1
    end
    return undef, latest
end


function selectValue(instance::Problem, var_names::Array,var::Variable, i::Int, latest::Int, sizeTree::Int)
    while var.index_domain > 0
        a = var.domain[var.index_domain]
        var.index_domain -= 1
        consist = true
        k = 1
        while k < i && consist
            if k > latest
                latest = k
            end
            if !consistant(instance, var_names, k, i, a)
                consist = false
            else
                k += 1
                sizeTree += 1
            end
        end
        if consist
            return a, latest, sizeTree
        end
    end
    if latest == i
        latest -= 1
    end
    return undef, latest, sizeTree
end


function backjumping(instance::Problem, init_time::Real=0.0, maxTime::Real=Inf,
    applyMACR=true, applyFC=true, applyMAC=false, sortVariablesBy="size_domain")

    sizeTree = 0

    ## sort the variables
    n = length(instance.variables)
    var_names = instance.order_variables
    if sortVariablesBy == "size_domain"
        sort!(var_names, by = x -> size_domain(instance.variables[x]))
    else
        if sortVariablesBy == "nb_constraints"
            sort!(var_names, by = x -> instance.variables[x].nb_constraints)
        end
    end

    ## MAC at the root
    if applyMACR
        isInconsistent = AC4(instance)
        if isInconsistent
            return false, sizeTree
        end
    end

    # keep track of the virtual domain
    _index_domain_lower = Dict(var.ID => var.index_domain_lower for var in values(instance.variables))
    _index_domain = Dict(var.ID => var.index_domain for var in values(instance.variables))

    i = 1
    latest = 0
    while i > 0 && i <= n

        # check if the delta_time <= maxTime in the solver
        if time() - init_time > maxTime
            return false, sizeTree
        end

        var = instance.variables[var_names[i]]
        if i != latest
            var.index_domain = _index_domain[var.ID]
        end
        val, latest, sizeTree = selectValue(instance, var_names, var, i, latest, sizeTree)
        if val == undef
            i = latest
        else
            var.value = val
            i += 1
            latest = 0
        end
    end

    # restore the virtual domain            # TODO : restore the virtual domain is really necessary ?
    for var in values(instance.variables)
        var.index_domain_lower = _index_domain_lower[var.ID]
        var.index_domain = _index_domain[var.ID]
    end

    if i == 0
        return false, sizeTree # inconsistant
    else
        return true, sizeTree  # we found a solution
    end
end
