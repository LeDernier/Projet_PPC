include("instance.jl")

function alldiff(var::Vector{Int64}, instance::Instance)
    nbVarDif = length(var)
    for i in 1:nbVarDif-1
        var1 = var[i]
        for j in i+1:nbVarDif
            var2 = var[j]
            values = [(x, y) for x in instance.domains[var1] for y in instance.domains[var2] if x != y]
            c = Constraint(var1, var2, values)
            push!(instance.constraints, c) #do we change instance out of the function here?
        end
    end
    return instance
end