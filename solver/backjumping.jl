
using ..Instance: Problem, Variable, getVariable        # .. because the include(..model/instance.jl) should be done in the file that includes this file


function consistant(instance::Problem, var_names::Array, k::Int, i::Int, a::Real)
    # check that all constraints are ok with the affectation
    # do we need to check a1, ... aK ? or is it the same with only current a ?
    x_name = var_names[i]
    for (key, c) in instance.constraints
        var1 = getVariable(instance, c.varsIDs[1])
        var2 = getVariable(instance, c.varsIDs[2])
        if var1.ID in var_names[1:k]
            if var2.ID in var_names[1:k]
                if !((var1.value, var2.value) in c.feasible_points)
                    return false
                end
            elseif var2.ID == x_name && !((var1.value, a) in c.feasible_points)
                return false
            elseif !(var1.value in [p[1] for p in c.feasible_points])
                return false
            end
        elseif var2.ID in var_names[1:k]
            if var1.ID == x_name && !((a, var2.value) in c.feasible_points)
                return false
            elseif !(var2.value in [p[2] for p in c.feasible_points])
                return false
            end
        end
    end
    return true
end


function selectValue(instance::Problem, var_names::Array, D::Vector, i::Int, latest::Int)
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
    return undef, latest
end


function backjumping(instance::Problem)
    n = length(instance.variables)
    latests = Array{Int, 1}(undef, n)
    domains = Array{Vector, 1}(undef, n)
    var_names = collect(keys(instance.variables)) 
    # TODO: sort var_names so that we go through the list in a better order
    # for instance, sort in increasing domain size

    # TODO: avoid copies of domains, use index_domain instead

    i = 1
    latest = 0
    while i > 0 && i <= n
        var = instance.variables[var_names[i]]
        if isassigned(domains, i)
            domain = domains[i]
        else
            domain = copy(var.domain)
        end     
        val, latest = selectValue(instance, var_names, domain, i, latest)
        domains[i] = domain
        latests[i] = latest
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
