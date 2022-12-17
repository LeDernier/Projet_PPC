#include("../model/instance.jl")                # this should be included in the main file # TODO: remove
using ..Instance: Problem, Variable, addConstraint, addConstraints, BConstraint
using ..Wrapper: all_different

function Benchmark.queens_cp(n::Int)::Problem

    # create the variables
    variables = Vector{Variable}()
    for i in 1:n
        line_i = Variable("line $i", collect(1:n), undef)
        push!(variables, line_i)
    end

    # create the instance
    instance = Problem(variables)

    # add the constraints
    #all_different(instance)                         # TODO : remove
    addConstraints(instance, all_different(variables))
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

function Benchmark.queens_lp(n::Int)::Problem

    # create the variables
    variables = Vector{Variable}()
    for i in 1:n
        line_i = Variable("line $i", collect(1:n), undef)
        push!(variables, line_i)
    end

    # create the instance
    instance = Problem(variables)

    # add the constraints
    addConstraints(instance, all_different(variables))
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
