module Instance
    

    include("cp_operands.jl")
    include("lp_operands.jl")
    include("operations.jl")
    

    import .BOperands: Variable, Variables, BConstraint
    import .LpOperands: LpAffineExpression, LpConstraint, _varMapType
    

    export Variable,Variables, BConstraint,
    +, -, *,
    Instance_BCSP, addVariables, getVariable, addConstraints, addConstraint, nbConstraints, nbVariables, makeExplicit,
    all_diff, diff, eq, inf_eq
    

    ### INSTANCE OF A CSP ###

    mutable struct Instance_BCSP
        """
            Instance of a binary constraint satisfaction problem.
        """
        variables::Dict{Union{String,Int}, Variable}
        constraints::Vector{BConstraint}

        function Instance_BCSP()
            """
                Empty constructor (the variables and constraints are added later).
            """
            vars = Dict{Union{String,Int}, Variable}()
            constrs = Vector{BConstraint}()
            return new(vars, constrs)
        end

        function Instance_BCSP(variables::Vector{Variable})
            """
                Unconstraint constructor (the constraints can be added later).
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = Vector{BConstraint}()
            return new(vars, constrs)
        end

        function Instance_BCSP(variables::Vector{Variable}, constraints::Vector{BConstraint})
            """
                Standard constructor.
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = constraints
            return new(vars, constrs)
        end
    end
    
    ## Include wrapper after the definition of Instance_BCSP

    include("wrapper.jl")
    import .Wrapper: all_diff, diff, eq, inf_eq

    function nbVariables(instance::Instance_BCSP)
        """
            Returns the Real of variables in the instance.
        """
        return length(instance.variables)
    end

    function nbConstraints(instance::Instance_BCSP)
        """
            Returns the Real of constraints in the instance.
        """
        return length(instance.constraints)
    end

    function addVariables(instance::Instance_BCSP, variables::Vector{Variable})
        for variable in variables
            if haskey(instance.variables, variable.ID)
                @warn "A variable has been replaced : same ID."
            end 
            instance.variables[variable.ID] = variables
        end
    end

    function getVariable(instance::Instance_BCSP, varID::Union{String,Int})
        return instance.variables[varID]
    end


    ### ADD A BINARY CONSTRAINT TO THE INSTANCE ###

    function addConstraints(instance::Instance_BCSP, constraints::Vector{BConstraint})
        for constraint in constraints
            push!(instance.constraints, constraint)
        end
    end

    function addConstraint(instance::Instance_BCSP, constraint::BConstraint)
        addConstraints(instance, [constraint])
    end

    ## String representation ##

    function reprInstance(instance::Instance_BCSP)
        println("\nVariables:")
        for var in keys(instance.variables)
            println(var)
        end
        println("\nConstraints:")
        for c in instance.constraints
            println(c)
        end
    end

    Base.show(io::IO, instance::Instance_BCSP) = print(io, reprInstance(instance))


    ### ADD A LINEAR CONSTRAINT TO THE INSTANCE ###

    function makeExplicit(constr::LpConstraint)
        """ 
            constr: Linear constraint having a reference to the variables appearing in 
            the right-hand side.
        """

        # create a dictionary (k => v) such that k=var.ID and v=var.feasible_points
        vars = Vector{_varMapType}()
        varsValues = []
        for (var,varCoeff) in constr.lhs.terms
            push!(vars, var)
            push!(varsValues, var.domain)
        end
        
        cartesianProduct = Iterators.product((varValues for varValues in varsValues)...)
        feasibleValues = Vector{Tuple}()
        for valueVars in cartesianProduct
            # calculate the value of the constraint left-hand side using the fact that the expression is ordered
            valueLHS = constr.lhs.constant
            for i in range(1, length(valueVars))
                coeff = constr.lhs.terms[vars[i]]
                valueLHS += coeff * valueVars[i]
            end
            
            # add the point to the feasible points if it satisfies the constraint
            if constr.relation(valueLHS,constr.rhs)
                push!(feasibleValues, valueVars)
            end 
        end

        # return the list of variables ids (the order) and the feasible values
        return feasibleValues
    end

    function addConstraints(instance::Instance_BCSP, constraints::Vector{<:LpConstraint})
        for constraint in constraints
            varsnames = [var.ID for var in collect(keys(constraint.lhs.terms))]
            feasible_points = makeExplicit(constraint)
            push!(instance.constraints, BConstraint(varsnames, feasible_points))
        end
    end

    function addConstraint(instance::Instance_BCSP, constraint::LpConstraint)
        addConstraints(instance, [constraint])
    end
end