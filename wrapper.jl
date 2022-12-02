include("model.jl")

function all_diff(instance::Instance_BCSP)
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

function diff(var1::Variable, var2::Variable, coef1, coef2, value, instance::Instance_BCSP)
    name1 = var1.name
    name2 = var2.name
    constraint_name = "diff_$coef1"*name1*"+$coef2"*name2*"_from_$value"
    values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y != value]
    c = BConstraint(constraint_name, (name1, name2), (var1.index, var2.index), values)
    push!(instance.constraints, c)
end

function eq(var1::Variable, var2::Variable, coef1, coef2, value, instance::Instance_BCSP)
    name1 = var1.name
    name2 = var2.name
    constraint_name = "eq_$coef1"*name1*"+$coef2"*name2*"_from_$value"
    values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y == value]
    c = BConstraint(constraint_name, (name1, name2), (var1.index, var2.index), values)
    push!(instance.constraints, c)
end

function inf_eq(var1::Variable, var2::Variable, coef1, coef2, value, instance::Instance_BCSP)
    name1 = var1.name
    name2 = var2.name
    constraint_name = "inf_$coef1"*name1*"+$coef2"*name2*"_from_$value"
    values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y <= value]
    c = BConstraint(constraint_name, (name1, name2), (var1.index, var2.index), values)
    push!(instance.constraints, c)
end