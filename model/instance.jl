module Instance
    

    include("cp_operands.jl")
    include("lp_operands.jl")
    include("operations.jl")

    import .BOperands: Variable, BConstraint, num_dVariables
    using .LpOperands: LpAffineExpression, LpConstraint, +, -, *, ==, <=, >=, !=, value, _varMapType
    

    export Variable, BConstraint,
    +, -, *, ==, <=, >=, !=,
    Problem, addVariables, getVariable, addConstraints, addConstraint, addObjective, nbConstraints, nbVariables, makeExplicitBinary
    

    ### INSTANCE OF A CSP ###

    mutable struct Problem
        """
            Instance of a two-variable problem. It can be a constraint satisfaction problem 
            or an optimization problem.
        """
        variables::Dict{Union{String,Int,Tuple}, Variable}
        constraints::Dict{Union{String,Int}, BConstraint}
        objective::Union{LpAffineExpression, Variable, Nothing}   # optional
        sense::Integer                                  # 0: satisfaction, 1: minimization, -1: maximization

        function Problem()
            """
                Empty constructor (the objective, variables and constraints are added later).
            """
            vars = Dict{Union{String,Int}, Variable}()
            constrs = Dict{Union{String,Int},BConstraint}()
            objective = nothing
            sense = 0

            return new(vars, constrs, objective, sense)
        end
        
        function Problem(variables::AbstractArray{Variable}, 
                        objective::Union{LpAffineExpression, Nothing}=nothing, 
                        sense=0)
            """
                Unconstraint constructor (the constraints can be added later).
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = Dict{Union{String,Int},BConstraint}()
            if isnothing(objective) || sense == 0
                sense = 0
                objective = nothing
            end
            sense = sign(sense)
            return new(vars, constrs, objective, sense)
        end

        function Problem(variables::AbstractArray{Variable}, 
                        constraints::Vector{BConstraint}, 
                        objective::Union{LpAffineExpression, Nothing}=nothing, 
                        sense=0)
            """
                Standard constructor.
            """
            vars = Dict(var.ID => var for var in variables)
            constrs = Dict(constr.ID => constr for constr in constraints)
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
            instance.variables[variable.ID] = variable
        end
    end

    function getVariable(instance::Problem, varID::Union{String,Int})
        return instance.variables[varID]
    end


    ### ADD A BINARY CONSTRAINT TO THE INSTANCE ###

    function addConstraints(instance::Problem, constraints::Vector{BConstraint})
        for constraint in constraints
            if ~(constraint.ID in keys(instance.constraints))
                #push!(instance.constraints, constraint)        # TODO: remove
                instance.constraints[constraint.ID] = constraint
            end
        end
    end

    function addConstraint(instance::Problem, constraint::BConstraint)
        addConstraints(instance, [constraint])
    end

    ## String representation ##

    function reprInstance(instance::Problem)
        maxVarsToShow = 100
        maxConstrToShow = 600

        ## variables

        numV = length(instance.variables) # number of variables
        println("\nVariables: "*string(numV))
        if numV <= maxVarsToShow
            for var in values(instance.variables)
                println(string(var)*": "*string(var.value))
            end
        end

        ## objective
        if instance.sense != 0
            println("\nObjective: ")
            obj = string(instance.objective)
            if instance.sense == 1
                println("Minimize "*obj)
            else
                if instance.sense == -1
                    println("Maximize "*obj)
                end
            end
        end

        ## constraints
        numC = length(instance.constraints) # number of constraints
        println("\nConstraints: "*string(numC))
        if numC <= maxConstrToShow
            for c in values(instance.constraints)
                println(c)
            end
        end
    end

    Base.show(io::IO, instance::Problem) = print(io, reprInstance(instance))


    ### ADD A LINEAR CONSTRAINT TO THE INSTANCE ###

    function makeExplicitBinary(constr::LpConstraint)
        """ 
            constr: Linear constraint having a reference to the two variables appearing in 
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
        isGreaterOrEqual = typeof(constr.relation) == UnionAll          # if constr.relation is: <=
        isFunction = typeof(constr.relation) == Function
            
        for valueVars in cartesianProduct
            # calculate the value of the constraint left-hand side using the fact that the expression is ordered
            valueLHS = value(constr.lhs, valueVars)
            
            # add the point to the feasible points if it satisfies the constraint
            if isFeasiblePoint(isGreaterOrEqual, isFunction, constr.rhs, valueLHS, constr.relation)
                push!(feasibleValues, valueVars)
            end
        end


        # return the list of variables ids (the order) and the feasible values
        return feasibleValues
    end

    function isFeasiblePoint(isGreaterOrEqual::Bool, isFunction::Bool, constr_rhs::Real, 
                            valueLHS::Real, constr_relation::Any)
        """
        Parameters    
            - isGreaterOrEqual: true if the constraint relation is =>
            - isFunction: true if the constraint relation is a function (usually if it is not =>)
            - constr_rhs: constraint right-hand side
            - valueLHS: value of the constraint left-hand side
            - constr_relation: constraint relation (usually a function)
        """
        
        isFeasible = false
        if isGreaterOrEqual
            if constr_rhs <= valueLHS
                isFeasible = true
            end
        else
            if isFunction && constr_relation(valueLHS,constr_rhs)
                isFeasible = true
            end 
        end

        return isFeasible
    end


    function addConstraints(instance::Problem, constraints::Vector{<:LpConstraint})
        dualVars = Vector{Variable}()
        for constraint in constraints
            if ~(constraint.ID in keys(instance.constraints))
                varsnames = [var.ID for var in collect(keys(constraint.lhs.terms))]
                feasible_points = makeExplicitBinary(constraint)
                if length(varsnames) == 2
                    bconstr = BConstraint(varsnames, feasible_points)
                    instance.constraints[bconstr.ID] = bconstr
                else
                    # if number of variables > 2, create a dual variable representing the constraint
                    num_dVariables[] += 1
                    dualVar = Variable("dual_"*string(num_dVariables[]), feasible_points)
                    dualVar.primal_vars_ids = Tuple(varsnames)
                    push!(dualVars,dualVar)
                end
            end
        end

        if length(dualVars) > 0
            # add the dual variables
            addVariables(instance, dualVars)

            # add the hidden-variables constraints
            for dualVar in dualVars
                primal_vars_ids = dualVar.primal_vars_ids
                dualVarDomain = dualVar.domain
                for i in 1:length(primal_vars_ids)
                    varsnames = [string(primal_vars_ids[i]), string(dualVar.ID)]        # constraint name = (primal vars IDS, dual var ID)
                    feasible_points = Vector{Tuple}()
                    for valDual in dualVarDomain
                        valueVars = (valDual[i], valDual)
                        push!(feasible_points, valueVars)
                    end
                    bconstr = BConstraint(varsnames, feasible_points)
                    instance.constraints[bconstr.ID] = bconstr
                end
            end
        end
    end

    function addConstraint(instance::Problem, constraint::LpConstraint)
        addConstraints(instance, [constraint])
    end

    function addObjective(instance::Problem, objective::Union{LpAffineExpression, Variable}, sense::Integer=1)
        """
            objective: affine expression.
            sense: 1 Minimize (by default), -1 Maximize
        """
        if sense == 1 || sense == -1
            instance.objective = objective
            instance.sense = sense
        end
    end
end