module Instance
    

    include("cp_operands.jl")
    include("lp_operands.jl")
    include("operations.jl")

    import .BOperands: Variable, BConstraint, num_dVariables, _varIDType, _varValueType, size_domain
    using .LpOperands: LpAffineExpression, LpConstraint, +, -, *, ==, <=, >=, !=, value, _varMapType
    

    export Variable, BConstraint, _varIDType, _varValueType, size_domain,
    +, -, *, ==, <=, >=, !=,
    Problem, addVariables, getVariable, addConstraints, addConstraint, addObjective, nbConstraints, nbVariables, makeExplicitBinary
    

    ### INSTANCE OF A CSP ###

    mutable struct Problem
        """
            Instance of a two-variable problem. It can be a constraint satisfaction problem 
            or an optimization problem.
        """
        variables::Dict{_varIDType, Variable}
        constraints::Dict{Union{String,Int}, BConstraint}
        objective::Union{Variable, Nothing}   # optional
        sense::Integer                                  # 0: satisfaction, 1: minimization, -1: maximization
        order_variables::Vector{_varIDType}                    # order of the variables when solving the problem

        function Problem()
            """
                Empty constructor (the objective, variables and constraints are added later).
            """
            vars = Dict{Union{String,Int}, Variable}()
            constrs = Dict{Union{String,Int},BConstraint}()
            objective = nothing
            sense = 0

            return new(vars, constrs, objective, sense, [])
        end
        
        function Problem(variables::AbstractArray{Variable}, 
                        objective::Union{Variable, Nothing}=nothing, 
                        sense=0)
            """
                Unconstraint constructor (the constraints can be added later).
            """
            vars = Dict(var.ID => var for var in variables)
            order_variables = [var.ID for var in variables]
            constrs = Dict{Union{String,Int},BConstraint}()
            if isnothing(objective) || sense == 0
                sense = 0
                objective = nothing
            end
            sense = sign(sense)
            return new(vars, constrs, objective, sense, order_variables)
        end

        function Problem(variables::AbstractArray{Variable}, 
                        constraints::Vector{BConstraint}, 
                        objective::Union{LpAffineExpression, Nothing}=nothing, 
                        sense=0)
            """
                Standard constructor.
            """
            vars = Dict(var.ID => var for var in variables)
            order_variables = [var.ID for var in variables]
            constrs = Dict(constr.ID => constr for constr in constraints)
            
            if isnothing(objective) || sense == 0
                sense = 0
                objective = nothing
            end

            # count the number of constraints in which a variable appears
            for constr in constrs
                constr.variables[1].nb_constraints += 1
                constr.variables[2].nb_constraints += 1
            end

            sense = sign(sense)
            return new(vars, constrs, objective, sense, order_variables)
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
            push!(instance.order_variables, variable.ID)
        end
    end

    function getVariable(instance::Problem, varID::Union{String,Int})
        return instance.variables[varID]
    end


    ### ADD A BINARY CONSTRAINT TO THE INSTANCE ###

    function addConstraints(instance::Problem, constraints::Vector{BConstraint})
        """
            The list of binary constraints are added to the instance of a problem.
            
            If there are a set of constraints acting on the same pair of variables, 
            then the feasible points are intersected. Therefore, there will only be 
            a constraint per pair of variables.
        """
        for constraint in constraints
            
            if constraint.ID in keys(instance.constraints)
                # if there already exists a constraint on the variables x,y,...
                # ...intersect the new and the existing binary constraint
                intersect_constraint(instance, constraint.ID, constraint)
            else
                varsnames = reverse([string(id_var) for id_var in constraint.varsIDs])
                name_bconstr_rev = "bC_"*varsnames[2]*"_"*varsnames[1]
                if name_bconstr_rev in keys(instance.constraints)
                    # if there already exists a constraint on the variables y,x,...
                    # ...intersect the new constraint reversed and the existing binary constraint
                    constraint.feasible_points = [(point[2],point[1]) for point in feasible_points]
                    intersect_constraint(instance, name_bconstr_rev, constraint)
                else
                    # add the constraint if there are no constraint on the variables x,y
                    instance.constraints[constraint.ID] = constraint

                    # count the number of constraints in which a variable appears
                    instance.variables[constraint.varsIDs[1]].nb_constraints += 1
                    instance.variables[constraint.varsIDs[2]].nb_constraints += 1
                end
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
                #println(string(var)*": "*string(var.value), ", domain: ", var.domain[var.index_domain_lower:var.index_domain])
                #= i_min = var.index_domain_lower
                i_max = var.index_domain
                println(string(var)*": "*string(var.value), ", (i_min,i_max): (", i_min, ", ", i_max, ")") =#
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
        #= println("\nvars: ", vars)
        println("varsValues: ", varsValues, "\n") =#
        cartesianProduct = Iterators.product((varValues for varValues in varsValues)...)
        feasibleValues = Vector{Tuple}()
            
        for valueVars in cartesianProduct
            # calculate the value of the constraint left-hand side using the fact that the expression is ordered
            valueLHS = value(constr.lhs, valueVars)
            
            # add the point to the feasible points if it satisfies the constraint
            if isFeasiblePoint(constr.rhs, valueLHS, constr.relation)
                push!(feasibleValues, valueVars)
                #println("Constraint: ", constr.ID, ", point: ", valueVars, ", Feasible")
            else
                #println("Constraint: ", constr.ID, ", point: ", valueVars, ", Infeasible")
            end
        end


        # return the list of variables ids (the order) and the feasible values
        return feasibleValues
    end

    function isFeasiblePoint(constr_rhs::Real, 
                            valueLHS::Real, constr_relation::Any)
        """
        Parameters    
            - constr_rhs: constraint right-hand side
            - valueLHS: value of the constraint left-hand side
            - constr_relation: constraint relation (usually a function)
        """
        
        isFeasible = false
        if constr_relation(valueLHS,constr_rhs)
            isFeasible = true
        end

        return isFeasible
    end


    function addConstraints(instance::Problem, constraints::Vector{<:LpConstraint})
        """
            The list of linear constraints (lp) are converted to a list of binary 
            constraints. Then, they are added to the instance of a problem.
            
            If there are a set of constraints acting on the same pair of variables, 
            then the feasible points are intersected. Therefore, there will only be 
            a constraint per pair of variables.
        """

        dualVars = Vector{Variable}()
        for constraint in constraints
            if ~(constraint.ID in keys(instance.constraints))
                varsnames = [string(var.ID) for var in collect(keys(constraint.lhs.terms))]
                feasible_points = makeExplicitBinary(constraint)
                if length(varsnames) == 2
                    name_bconstr = "bC_"*varsnames[1]*"_"*varsnames[2]
                    bconstr = BConstraint(name_bconstr ,varsnames, feasible_points)
                    if name_bconstr in keys(instance.constraints)
                        # if there already exists a constraint on the variables x,y,...
                        # ...intersect the new and the existing binary constraint
                        intersect_constraint(instance, name_bconstr, bconstr)
                    else
                        varsnames = reverse(varsnames)
                        name_bconstr_rev = "bC_"*varsnames[2]*"_"*varsnames[1]
                        if name_bconstr_rev in keys(instance.constraints)
                            # if there already exists a constraint on the variables y,x,...
                            # ...intersect the new constraint reversed and the existing binary constraint
                            feasible_points = [(point[2],point[1]) for point in feasible_points]
                            bconstr = BConstraint(name_bconstr ,varsnames, feasible_points)
                            intersect_constraint(instance, name_bconstr_rev, bconstr)
                        else
                            # add the constraint if there are no constraint on the variables x,y
                            instance.constraints[bconstr.ID] = bconstr

                            # count the number of constraints in which a variable appears
                            instance.variables[varsnames[1]].nb_constraints += 1
                            instance.variables[varsnames[2]].nb_constraints += 1
                        end
                    end
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

                    # count the number of constraints in which a variable appears
                    instance.variables[varsnames[1]].nb_constraints += 1
                    instance.variables[varsnames[2]].nb_constraints += 1
                end
            end
        end
    end

    function addConstraint(instance::Problem, constraint::LpConstraint)
        addConstraints(instance, [constraint])
    end

    function addObjective(instance::Problem, objective::Variable, sense::Integer=1)
        """
            objective: affine expression.
            sense: 1 Minimize (by default), -1 Maximize
        """
        if sense == 1 || sense == -1
            # sort the domain in descending order if minimization 
            #= if sense == 1 && last(objective.domain) > first(objective.domain)
                objective.domain = sort(objective.domain, rev=true)
            else
                # sort the domain in ascending order if maximization
                if sense == -1 && last(objective.domain) < first(objective.domain)
                    objective.domain = sort(objective.domain)
                end
            end =#
            instance.objective = objective
            instance.sense = sense 
        end

        addVariables(instance, [objective])        
    end

    function intersect_constraint(instance::Problem, id_existingBConstraint, newBConstraint::BConstraint)
        existingBConstraint = instance.constraints[id_existingBConstraint]
        filter!(e -> e in newBConstraint.feasible_points, existingBConstraint.feasible_points)
    end
end