include("model.jl")

function queens_instance(n::Int)::Instance_BCSP

    # create the variables
    variables = []
    for i in 1:n
        line_i = Variable("line $i", i, collect(1:n), undef)
        push!(variables, line_i)
    end

    # create the instance
    instance = Instance_BCSP(variables,[])

    # add the constraints
    all_diff(instance)
    for i in 1:n-1
        var1 = variables[i]
        name1 = var1.name
        idx1 = var1.index
        for j in i+1:n
            var2 = variables[j]
            values = [(x, y) for x in var1.domain for y in var2.domain if abs(x-y) != j-i]
            c = BConstraint("diag$i$j", (name1, var2.name), (idx1, var2.index), values)
            push!(instance.constraints, c)
        end
    end
    return instance
end
