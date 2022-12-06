module Instance
    

    include("cp_operands.jl")
    include("lp_operands.jl")
    include("operations.jl")
    

    import .BOperands: Variable, Variables, BConstraint
    import .LpOperands: LpAffineExpression, LpConstraint, _varMapType
    

    export Variable,Variables, BConstraint,
    +, -, *,
    Instance_BCSP, addVariables, addConstraints, addConstraint, nbConstraints, nbVariables, makeExplicit
    

    ### INSTANCE OF A CSP ###

    mutable struct Instance_BCSP
        """
            Instance of a binary constraint satisfaction problem.
        """
        variables::Vector{Variable}
        constraints::Vector{BConstraint}

        function Instance_BCSP()
            """
                Empty constructor (the variables and constraints are added later).
            """
            vars = Vector{Variable}()
            constrs = Vector{BConstraint}()
            return new(vars, constrs)
        end

        function Instance_BCSP(variables::Vector{Variable})
            """
                Unconstraint constructor (the constraints can be added later).
            """
            vars = variables
            constrs = Vector{BConstraint}()
            return new(vars, constrs)
        end

        function Instance_BCSP(variables::Vector{Variable}, constraints::Vector{BConstraint})
            """
                Standard constructor.
            """
            vars = variables
            constrs = constraints
            return new(vars, constrs)
        end
    end
    
    ## Include wrapper after the definition of Instance_BCSP

    include("wrapper.jl")
    import .Wrapper: all_diff, diff, eq, inf_eq
    export all_diff, diff, eq, inf_eq

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
            push!(instance.variables, variables)
        end
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
        for var in instance.variables
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

    function makeExplicit(constr::LpConstraint, vars::Vector{Variable})
        # DEPRECATED 
        # TODO : remove when makeExplicit(::LpConstraint) will be available
        """ 
            Returns the values of variables that satisfy the linear constraint.

            constr: Linear constraint.
            vars: Vector of variables appearing in the constraint.
        """

        # get the positions in 'vars' of those variables appearing in the constraint
        posVarsInConstr = Dict()
        pos_var = 1
        for var in vars
            if haskey(constr.lhs.terms, var.ID)
                posVarsInConstr[var.ID] = pos_var
            end
            pos_var += 1
        end

        # create a dictionary (k => v) such that k=var.ID and v=var.feasible_points
        varsIDs = Vector{String}()
        varsValues = []
        for (varID,varCoeff) in constr.lhs.terms
            # assert that all the variables of the constraint have been passed in 'vars'
            if ~(haskey(posVarsInConstr, varID))
                error("Trying to evaluate a LpAffineExpression without the value of some variables.")
            end
            push!(varsIDs, varID)
            push!(varsValues, vars[posVarsInConstr[varID]].domain)
        end
        
        cartesianProduct = Iterators.product((varValues for varValues in varsValues)...)
        feasibleValues = Vector{Tuple}()
        for point in cartesianProduct
            # calculate the value of the constraint left-hand side using the fact that the expression is ordered
            valueLHS = constr.lhs.constant
            for i in range(1, length(point))
                valueLHS += point[i]*constr.lhs.terms[varsIDs[i]]
            end
            
            # add the point to the feasible points if it satisfies the constraint
            if constr.relation(valueLHS,constr.rhs)
                push!(feasibleValues, point)
            end 
        end

        # return the list of variables ids (the order) and the feasible values
        return varsIDs, feasibleValues
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