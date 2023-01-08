using ..Instance: Problem, Variable, addConstraint, addConstraints, addVariables, BConstraint
using ..Wrapper: all_different

function addIntervalConstraints(n::Int, instance::Problem, v_variables::Vector{Variable}, s_variables::Vector{Variable})

    x_possible_values = Vector{Int}()
    for i in 1:n-1
        for j in 0:n-1
            for k in (i+j, j-i)
                if k >= 0 && k <= n-1
                    # i = abs(j-k) with j, k in [0, n-1]
                    x_val = 100*i+10*j+k
                    append!(x_possible_values, x_val)
                end
            end
        end
    end

    x_variables = Vector{Variable}()
    for i in 1:n-1
        x_i = Variable("x $i", x_possible_values, undef)
        push!(x_variables, x_i)
    end

    addVariables(instance, x_variables)

    for i in 1:n-1
        # v_var == abs(s_var_i - s_var_j)
        x_var = x_variables[i]
        v_var = v_variables[i]
        s_var_i = s_variables[i]
        s_var_j = s_variables[i+1]

        xv_feasible_points = [(x÷100, x) for x in x_var.domain]
        xv_constraint = BConstraint("bC_xv $i", [v_var.ID, x_var.ID], xv_feasible_points)
        #instance.constraints["bC_xv $i"] = xv_constraint
        addConstraint(instance, xv_constraint)

        xsi_feasible_points = [((x%100)÷10, x) for x in x_var.domain]
        xsi_constraint = BConstraint("bC_xsi $i", [s_var_i.ID, x_var.ID], xsi_feasible_points)
        #instance.constraints["bC_xsi $i"] = xsi_constraint
        addConstraint(instance, xsi_constraint)

        xsj_feasible_points = [((x%100)%10, x) for x in x_var.domain]
        xsj_constraint = BConstraint("bC_xsj $i", [s_var_j.ID, x_var.ID], xsj_feasible_points)
        #instance.constraints["bC_xsj $i"] = xsj_constraint
        addConstraint(instance, xsj_constraint)
    end

end


function allIntervalSeriesBinary(n::Int)::Problem
    # see https://www.csplib.org/Problems/prob007/

    if n>10
        println("ERROR: n = ", n, " > 10. The problem is not defined.")
        return undef
    end

    # create the variables
    s_variables = Vector{Variable}()
    v_variables = Vector{Variable}()
    for i in 1:n
        s_i = Variable("s $i", collect(0:n-1), undef)
        push!(s_variables, s_i)
        if i<n
            v_i = Variable("v $i", collect(1:n-1), undef)
            push!(v_variables, v_i)
        end
    end

    # create the instance
    instance = Problem(s_variables)
    addVariables(instance, v_variables)

    # add the constraints
    addConstraints(instance, all_different(s_variables))
    addConstraints(instance, all_different(v_variables))
    
    addIntervalConstraints(n, instance, v_variables, s_variables)

    return instance
end


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
    #println(instance)
    M = 2*n
    for i in 1:n-1
        v_var = v_variables[i]
        nu_var = nu_variables[i]
        s_var_i = s_variables[i]
        s_var_j = s_variables[i+1]
        s_var_diff = s_var_i - s_var_j

        # addConstraint(instance, v_variables[i] == abs(s_variables[i] - s_variables[i+1]))
        #addConstraint(instance, 0.0 <= v_var + s_var_diff)

        #= addConstraint(instance, v_var + s_var_diff >= 0.0)
        addConstraint(instance, v_var - s_var_diff >= 0.0)
        addConstraint(instance, v_var - M*nu_var <= s_var_diff)
        addConstraint(instance, v_var - M*(1-nu_var) <= -s_var_diff) =#

        addConstraint(instance, s_var_diff <= M*(1-nu_var))
        addConstraint(instance, s_var_diff >= -M*nu_var)
        addConstraint(instance, v_var - s_var_diff <= M*nu_var)
        addConstraint(instance, v_var - s_var_diff >= -M*nu_var)
    end

    return instance
end