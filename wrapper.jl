include("model.jl")

function alldiff(instance::Instance_BCSP)
    nbVarDif = length(instance.variables)
    for i in 1:nbVarDif-1
        var1 = instance.variables[i]
        name1 = var1.name
        for j in i+1:nbVarDif
            var2 = instance.variables[j]
            name2 = var2.name
            names = name1*'_'*name2
            values = [(x, y) for x in var1.domain for y in var2.domain if x != y]
            c = BConstraint("all_diff_$names", (name1, name2), (var1.index, var2.index), values)
            push!(instance.constraints, c)
        end
    end
end