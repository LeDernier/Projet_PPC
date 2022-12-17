module Instance
    

    include("cp_operands.jl")
    include("lp_operands.jl")
    include("operations.jl")

    import .BOperands: Variable, Variables, BConstraint
    using .LpOperands: LpAffineExpression, LpConstraint, _varMapType
    

    export Variable,Variables, BConstraint,
    +, -, *,
    Problem, addVariables, getVariable, addConstraints, addConstraint, nbConstraints, nbVariables, makeExplicit
    

    ### INSTANCE OF A CSP ###

    mutable struct Problem
        """
            Instance of a two-variable problem. It can be a constraint satisfaction problem 
            or an optimization problem.
        """
        variables::Dict{Union{String,Int}, Variable}
        constraints::Vector{BConstraint}
        objective::Union{LpAffineExpression, Nothing}   # optional
        sense::Integer                                  # 0: satisfaction, 1: minimization, -1: maximization

        function Problem()
            """
                Empty constructor (the objective, variables and constraints are added later).
            """
            vars = Dict{Union{String,Int}, Variable}()
            constrs = Vector{BConstraint}()
            objective = nothing
            sense = 0

            return new(vars, constrs, objective, sense)
        end
        
        function Problem(variables::Vector{Variable}, 
                        objective::Union{LpAffineExpression, Nothing}=nothing, 
                        sense=0)
            """
                Unconstraint constructor (the constraints can be added later).
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = Vector{BConstraint}()
            if isnothing(objective) || sense == 0
                sense = 0
                objective = nothing
            end
            sense = sign(sense)
            return new(vars, constrs, objective, sense)
        end

        function Problem(variables::Vector{Variable}, 
                        constraints::Vector{BConstraint}, 
                        objective::Union{LpAffineExpression, Nothing}=nothing, 
                        sense=0)
            """
                Standard constructor.
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = constraints
            if isnothing(objective) || sense == 0
                sense = 0
                objective = nothing
            end
            sense = sign(sense)
            return new(vars, constrs, objective, sense)
        end
    end

    function nbVariables(instance::Problem)
        """
            Returns the Real of variables in the instance.
        """
        return length(instance.variables)
    end

    function nbConstraints(instance::Problem)
        """
            Returns the Real of constraints in the instance.
        """
        return length(instance.constraints)
    end

    function addVariables(instance::Problem, variables::Vector{Variable})
        for variable in variables
            if haskey(instance.variables, variable.ID)
                @warn "A variable has been replaced : same ID."
            end 
            instance.variables[variable.ID] = variables
        end
    end

    function getVariable(instance::Problem, varID::Union{String,Int})
        return instance.variables[varID]
    end


    ### ADD A BINARY CONSTRAINT TO THE INSTANCE ###

    function addConstraints(instance::Problem, constraints::Vector{BConstraint})
        for constraint in constraints
            push!(instance.constraints, constraint)
        end
    end

    function addConstraint(instance::Problem, constraint::BConstraint)
        addConstraints(instance, [constraint])
    end

    ## String representation ##

    function reprInstance(instance::Problem)
        println("\nVariables:")
        for var in keys(instance.variables)
            println(var)
        end
        println("\nConstraints:")
        for c in instance.constraints
            println(c)
        end
    end

    Base.show(io::IO, instance::Problem) = print(io, reprInstance(instance))


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

    function addConstraints(instance::Problem, constraints::Vector{<:LpConstraint})
        for constraint in constraints
            varsnames = [var.ID for var in collect(keys(constraint.lhs.terms))]
            feasible_points = makeExplicit(constraint)
            push!(instance.constraints, BConstraint(varsnames, feasible_points))
        end
    end

    function addConstraint(instance::Problem, constraint::LpConstraint)
        addConstraints(instance, [constraint])
    end
end