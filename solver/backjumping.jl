function consistant(instance::Problem)
    return true
end


function selectValue(D::Vector, i::Tnt, latest::Int)
    while length(D) > 0
        a = pop!(D)
        consist = true
        k = 1
        while k < i && consist
            if k > latest
                latest = k
            end
            if !consistant() # to change
                consist = false
            else
                k += 1
            end
        end
        if consist
            return a, latest
        end
    end
    return -1, latest
end


function backjumping(instance::Problem)
    n = length(instance.variables)
    values = Array{Real, 1}(undef, n)
    domains = Array{Vector, 1}(undef, n)
    var_names = collect(keys(instance.variables))
    i = 1
    latest = 0
    var = instance.variables[var_names[i]]
    domain = copy(var.domain)
    while i >= 0 && i <= n
        val = selectValue(domain, i)
        domains[i] = domain
        values[i] = val
        if val == -1
            i = latest
            if isdefined(domains, i)
                domain = domains[i]
            else
                var = instance.variables[var_names[i]]
                domain = copy(var.domain)
            end
        else
            i += 1
            latest = 0
            var = instance.variables[var_names[i]]
            domain = copy(var.domain)
        end
    end
    if i == 0
        return -1  # inconsistant
    else
        return values  # we found a solution
    end
end