#= include("model/instance.jl")
using .Instance
 =#

 module Wrapper
    using ..Instance: Problem, Variable, BConstraint
    export all_different, different, equal, inf_equal

    #function all_diff(instance::Problem) # TODO : remove
    function all_different(variables::Vector{Variable})
        nbVarDif = length(variables)
        constraints = Vector{BConstraint}()
        for i in 1:nbVarDif-1
            var1 = variables[i]
            name1 = var1.ID
            for j in i+1:nbVarDif
                var2 = variables[j]
                name2 = var2.ID
                names = name1*'_'*name2
                values = [(x, y) for x in var1.domain for y in var2.domain if x != y]
                c = BConstraint("all_diff_$names", [name1, name2], values)
                
                #push!(instance.constraints, c)         # TODO : remove
                push!(constraints, c)
            end
        end

        return constraints
    end

    #function diff(var1::Variable, var2::Variable, coef1, coef2, value, instance::Problem)    # TODO : remove
    function different(var1::Variable, var2::Variable, coef1, coef2, value)
        """
            Returns a constraint of the form: coef1*var1 + coef2*var2 != value.
        """
        constraints = Vector{BConstraint}()
        name1 = var1.ID
        name2 = var2.ID
        constraint_name = "diff_$coef1"*name1*"+$coef2"*name2*"_from_$value"
        values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y != value]
        c = BConstraint(constraint_name, [name1, name2], values)
        #push!(instance.constraints, c)                 # TODO : remove
        push!(constraints, c)
        return constraints
    end

    #function eq(var1::Variable, var2::Variable, coef1, coef2, value, instance::Problem)  # TODO : remove
    function equal(var1::Variable, var2::Variable, coef1, coef2, value)
        """
            Returns a constraint of the form: coef1*var1 + coef2*var2 = value.
        """
        constraints = Vector{BConstraint}()
        name1 = var1.ID
        name2 = var2.ID
        constraint_name = "eq_$coef1"*name1*"+$coef2"*name2*"_from_$value"
        values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y == value]
        c = BConstraint(constraint_name, [name1, name2], values)
        #push!(instance.constraints, c)                 # TODO : remove
        push!(constraints, c)
        return constraint
    end

    #function inf_eq(var1::Variable, var2::Variable, coef1, coef2, value, instance::Problem)  # TODO : remove
    function inf_equal(var1::Variable, var2::Variable, coef1, coef2, value, instance::Problem)
        """
            Returns a constraint of the form: coef1*var1 + coef2*var2 <= value.
        """
        constraints = Vector{BConstraint}()
        name1 = var1.ID
        name2 = var2.ID
        constraint_name = "inf_$coef1"*name1*"+$coef2"*name2*"_from_$value"
        values = [(x, y) for x in var1.domain for y in var2.domain if coef1*x+coef2*y <= value]
        c = BConstraint(constraint_name, [name1, name2], values)
        #push!(instance.constraints, c)                 # TODO : remove
        push!(instance.constraints, c)
        return constraints
    end
end