using ..Instance: Problem, Variable, addConstraint, addConstraints, BConstraint
using ..Wrapper: all_different

function allIntervalSeries(n::Int)::Problem
    # see https://www.csplib.org/Problems/prob007/

    # create the variables
    s_variables = Vector{Variable}()
    v_variables = Vector{Variable}()
    for i in 1:n
        s_i = Variable("s $i", collect(0:n-1), undef)
        push!(s_variables, s_i)
        if i<n
            v_i = Variable("s $i", collect(1:n-1), undef)
            push!(v_variables, v_i)
        end
    end

    # create the instance
    instance = Problem()
    instance.addVariables(s_variables)
    instance.addVariables(v_variables)

    # add the constraints
    addConstraints(instance, all_different(s_variables))
    addConstraints(instance, all_different(v_variables))
    for i in 1:n-1
        addConstraint(instance, v_variables[i] == abs(s_variables[i] - s_variables[i+1]))
        # will it work ?
    end

    return instance
end