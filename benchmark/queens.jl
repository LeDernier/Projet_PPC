include("../model/instance.jl")
using .Instance

function queens_instance(n::Int)::Instance_BCSP

    # create the variables
    variables = Vector{Variable}()
    for i in 1:n
        line_i = Variable("line $i", collect(1:n), undef)
        push!(variables, line_i)
    end

    # create the instance
    instance = Instance_BCSP(variables)

    # add the constraints
    all_diff(instance)
    for i in 1:n-1
        var1 = variables[i]
        for j in i+1:n
            var2 = variables[j]
            values = [(x, y) for x in var1.domain for y in var2.domain if abs(x-y) != j-i]
            c = BConstraint("diag$i$j", [var1.ID, var2.ID], values)
            push!(instance.constraints, c)
        end
    end
    return instance
end

function queens_lp(n::Int)::Instance_BCSP

    # create the variables
    variables = Vector{Variable}()
    for i in 1:n
        line_i = Variable("line $i", collect(1:n), undef)
        push!(variables, line_i)
    end

    # create the instance
    instance = Instance_BCSP(variables)

    # add the constraints
    all_diff(instance)
    for i in 1:n-1
        var_i = variables[i]
        for j in i+1:n
            var_j = variables[j]
            addConstraint(instance, var_i - var_j != j - i)
            addConstraint(instance, var_j - var_i != j - i)
        end
    end

    return instance
end
