using ..Instance: Problem, Variable, addConstraint, addConstraints, addVariables, BConstraint
using ..Wrapper: all_different

function allIntervalSeries(n::Int)::Problem
    # see https://www.csplib.org/Problems/prob007/

    # create the variables
    s_variables = Vector{Variable}()
    v_variables = Vector{Variable}()
    nu_variables = Vector{Variable}()
    for i in 1:n
        s_i = Variable("s $i", collect(0:n-1), undef)
        push!(s_variables, s_i)
        if i<n
            v_i = Variable("v $i", collect(1:n-1), undef)
            push!(v_variables, v_i)
            nu_i = Variable("nu $i", collect(0:1), undef)
            push!(nu_variables, nu_i)
        end
    end

    # create the instance
    instance = Problem(s_variables)
    addVariables(instance, v_variables)
    addVariables(instance, nu_variables)

    # add the constraints
    addConstraints(instance, all_different(s_variables))
    addConstraints(instance, all_different(v_variables))
    println("line 30")
    println(instance)
    M = 2*n
    for i in 1:n-1
        v_var = v_variables[i]
        nu_var = nu_variables[i]
        s_var_i = s_variables[i]
        s_var_j = s_variables[i+1]
        s_var = s_var_i - s_var_j
        # addConstraint(instance, v_variables[i] == abs(s_variables[i] - s_variables[i+1]))
        #addConstraint(instance, 0.0 <= v_var + s_var)
        addConstraint(instance, v_var + s_var => 0.0)
        addConstraint(instance, v_var - s_var => 0.0)
        addConstraint(instance, v_var - M*nu_var <= s_var_i - s_var_j)
        addConstraint(instance, v_var_i - M*(1-nu_vari_i) <= s_var_j - s_var_i)
    end

    return instance
end