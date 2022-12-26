
module BackjumpingSolver

    using ..Instance: Problem, getVariable        # .. because the include(..model/instance.jl) should be done in the file that includes this file

    export backjumping

    
    function consistant(instance::Problem, var_names::Array, k::Int, i::Int, a::Real)
        # check that all constraints are ok with the affectation
        # do we need to check a1, ... aK ? or only current a ?
        x_name = var_names[i]
        for c in instance.constraints
            var1 = c.varsIDs[1] # use getVariable here !!!!
            var2 = c.varsIDs[2] # use getVariable here !!!!
            if var1.name in var_names[1:k]
                if var2.name in var_names[1:k]
                    if !((var1.value, var2.value) in c.feasible_points)
                        return false
                    end
                elseif var2.name == x_name && !((var1.value, a) in c.feasible_points)
                    return false
                elseif !(var1.value in [p[1] for p in c.feasible_points])
                    return false
                end
            elseif var2.name in var_names[1:k]
                if var1.name == x_name && !((a, var2.value) in c.feasible_points)
                    return false
                elseif !(var2.value in [p[2] for p in c.feasible_points])
                    return false
                end
            end
        end
        return true
    end


    function selectValue(instance::Problem, var_names::Array, D::Vector, i::Tnt, latest::Int, var::Variable)
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
        var = instance.variables[var_names[i]]
        domain = copy(var.domain)
        while i > 0 && i <= n        
            var = instance.variables[var_names[i]]
            val, latest = selectValue(instance, var_names, domain, i, latest)
            domains[i] = domain
            latests[i] = latest
            if val == undef
                i = latest
                if isdefined(domains, i)
                    domain = domains[i]
                else
                    domain = copy(var.domain)
                end
            else
                var.value = val
                i += 1
                latest = 0
                var = instance.variables[var_names[i]]
                domain = copy(var.domain)
            end
        end
    
        if i == 0
            return false # inconsistant
        else
            return true  # we found a solution
        end
    end
end


