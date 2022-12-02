include("model.jl")

function backtrack(instance::Instance_BCSP)::Union{Tuple{Bool, Instance_BCSP}, Tuple{Bool, UndefInitializer}}

    # check that all constraints are respected
    for c in instance.constraints
        idx1 = c.variable_indices[1]
        idx2 = c.variable_indices[2]
        var1 = instance.variables[idx1].value
        var2 = instance.variables[idx2].value
        if var1 != undef && var2 != undef
            found_feasible_point = false
            for values in c.feasible_points
                if var1 == values[1] && var2 == values[2]
                    found_feasible_point = true
                    break
                end
            end
            if !found_feasible_point
                return false, undef
            end
        end
    end

    # check that some variables are undefined
    completed = true
    undefined_var = undef
    for var in instance.variables
        if var.value == undef
            completed = false
            undefined_var = var
            break
        end
    end
    if completed
        return true, instance
    end

    # here, undefined_var is the first variable undefined in the vector of the instance.
    # we could improve that in the future

    i_max = undefined_var.index_domain
    for current_value in undefined_var.domain[1:i_max]
        undefined_var.value = current_value
        if backtrack(instance)[1]
            return true, instance
        end
        undefined_var.value = undef
    end

    return false, undef
end

### TESTS ####

println("Let's test the backtrack algorithm")

found_sol, instance = backtrack(instance)
println("found a solution? ", found_sol)
print_instance(instance)

z = Variable("z", 1, collect(Float64, 0:5), undef)
t = Variable("t", 2, collect(0:5), undef)

c3 = BConstraint("c3", ("z", "t"), (1, 2), collect([(0,0), (0,1), (1,0)]))
c4 = BConstraint("c4", ("z", "t"), (1, 2), collect([(3,0),(2,1)]))

instance2 = Instance_BCSP(collect([z,t]),collect([c3,c4]))
print_instance(instance2)

println("Let's test the backtrack algorithm on the second instance")

found_sol, instance2 = backtrack(instance2)
println("found a solution? ", found_sol)