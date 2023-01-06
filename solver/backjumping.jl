
using ..Instance: Problem, Variable, getVariable
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


function selectValue(instance::Problem, var_names::Array,var::Variable, i::Int, latest::Int)
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


function backjumping(instance::Problem, init_time::Real=0.0, maxTime::Real=Inf, depth=0)

    if AC4(instance)
        return false
    end

    n = length(instance.variables)
    var_names = collect(keys(instance.variables))

    # sort var by increasing domain size
    # sort!(var_names, by = x -> instance.variables[x].index_domain - instance.variables[x].index_domain_lower)
    
    # sort var by decreasing domain size
    # sort!(var_names, rev = true, by = x -> instance.variables[x].index_domain - instance.variables[x].index_domain_lower)
    
    # sort var by nb of constraints
    # sort!(var_names, by = x -> instance.variables[x].nb_constraints)

    println("variable order: ", var_names)
    for var_name in var_names
        dom_size = instance.variables[var_name].index_domain - instance.variables[var_name].index_domain_lower
        nb_constraints = instance.variables[var_name].nb_constraints
        println("var ", var_name, " has a domain size of ", dom_size, " and ", nb_constraints, " constraints.")
    end

    i = 1
    latest = 0
    while i > 0 && i <= n

        # check if the delta_time <= maxTime in the solver
        if time() - init_time > maxTime
            return false
        end

        var = instance.variables[var_names[i]]
        if i != latest
            var.index_domain = length(var.domain)
        end
        val, latest = selectValue(instance, var_names, var, i, latest)
        if val == undef
            i = latest
        else
            var.value = val
            i += 1
            latest = 0
        end
    end

    if i == 0
        return false # inconsistant
    else
        return true  # we found a solution
    end
end
