"""
    Algorithms.
"""

module Solver

    #include("../model/instance.jl")                    # this should only be included in the main file
    include("constants.jl")
    
    using ..Instance: Problem, getVariable,addConstraint        # .. because the include(..model/instance.jl) should be done in the file that includes this file
    include("backtrack.jl")
    include("backjumping.jl")

    export backjumping, backtrack, solve, AC4

    function solve(instance::Problem, maxTime::Real=Inf)
        """
        Parameters
            - instance: problem instance.
            - maxTime: maximum time given to the solver to find the solution.
        """
        resolveOk = false
        solutionStatus = PSolutionNoSolutionFound
    
        init_time = time()

        ## filtering phase
        num_constr_before = length(instance.constraints)
        num_constr_removed = num_constr_before - length(instance.constraints)
        if num_constr_removed > 0
            println("Number of constraints removed by intersection: ", num_constr_removed, "/",num_constr_before)
        end
    
        ## resolution phase
        if instance.sense == 0
            resolveOk = actualSolveCSP(instance, init_time, maxTime)
            if resolveOk
                solutionStatus = PSolutionSolutionFound
            else
                solutionStatus = PSolutionInfeasible
            end
        else
            resolveOk, solutionStatus = actualSolveCOP(instance, init_time, maxTime) 
        end
        
    
        delta_time = time() - init_time
        status = get(PSolutionToStatus, solutionStatus, 0)
    
        return status, delta_time
    end

    function actualSolveCSP(instance::Problem, init_time::Real, maxTime::Real)
        """
            Solve an constraint satisfaction problem.
            Parameters
            - instance: problem instance.
            - init_time: initial time.
            - maxTime: maximum time given to the solver to find the solution.
        """
        return backtrack(instance, init_time, maxTime)
    end

    function actualSolveCOP(instance::Problem, init_time::Real, maxTime::Real)
        """
            Solve an constraint optimization problem. The objective should always be a Variable.

            Parameters
                - instance: problem instance.
                - init_time: initial time.
                - maxTime: maximum time given to the solver to find the solution.
        """
        statusSol = PSolutionNoSolutionFound

        obj_values = instance.objective.domain
        
        if instance.sense == PMaximize
            right_idx = 1
            left_idx = length(obj_values) 
        else
            right_idx = length(obj_values)
            left_idx = 1
        end

        middle_idx = right_idx

        ## estimate middle_idx by the dichotomy method ##
        resolveOk = false
        right_idx_resolveOk = false     # true if the solution associated to the right_idx is ok
        left_idx_resolveOk = false      # true if the solution associated to the left_idx is ok
        instance_copy = deepcopy(instance) 
        
        while true
            
            # backtrack on a copy of the instance
            #copyIndexDomain(instance, instance_copy)               # reset index_domain for each variable
            #instance_copy.objective.value = obj_values[middle_idx]
            instance_copy.objective.index_domain = middle_idx
            instance_copy.objective.index_domain_lower = middle_idx
            
            #instance_copy.objective <= obj_values[middle_idx]            # change the virtual domain of the objective variable
            makeFeasible(instance_copy)                                  # reset var variables; TODO: to improve using inverse backtracking
            test_index_domain(instance_copy)

            resolveOk = actualSolveCSP(instance_copy, init_time, maxTime)
           
            delta_time = time() - init_time
            if resolveOk
                copySolutionValues(instance_copy, instance)
                println("resolveOk with middle_idx: ", middle_idx, ", value: ", obj_values[middle_idx], ", delta_time: ", delta_time)
                right_idx_resolveOk = true
                right_idx = middle_idx
                middle_idx=floor(Integer, (left_idx+middle_idx)/2)
                if middle_idx == left_idx
                    if left_idx_resolveOk
                        resolveOk = true
                        println("last resolveOk with middle_idx: ", middle_idx, ", delta_time: ", delta_time)
                    else
                        println("last resolveNotOk with middle_idx: ", middle_idx, ", delta_time: ", delta_time)
                    end
                    
                    break
                end
            else
                println("resolveNotOk with middle_idx: ", middle_idx, ", delta_time: ", delta_time)
                left_idx_resolveOk = true
                left_idx = middle_idx
                middle_idx=ceil(Integer, (middle_idx+right_idx)/2)
                if middle_idx == right_idx
                    if right_idx_resolveOk
                        resolveOk = true
                        println("last resolveOk with middle_idx: ", middle_idx, ", delta_time: ", delta_time)
                    else
                        println("last resolveNotOk with middle_idx: ", middle_idx, ", delta_time: ", delta_time)
                    end
                    
                    break
                end
            end

            if time() - init_time >= maxTime
                println("time exceeded. Delta_time: ", time() - init_time)
                if right_idx_resolveOk
                    resolveOk = true
                end
                break
            end
        end

        ## get the instance associated to middle_idx if delta_time < maxTime##
        #= if instance.objective.value != obj_values[middle_idx] && time() - init_time < maxTime
            println("objective_val: ", instance.objective.value, ", obj_values[middle_idx]: ", obj_values[middle_idx])
            instance.objective.value = obj_values[middle_idx]
            instance.objective <= obj_values[middle_idx]
            resolveOk = actualSolveCSP(instance, init_time, maxTime)
        end =#

        if resolveOk
            statusSol = PSolutionOptimal
        else
            statusSol = PSolutionInfeasible
        end
        
        return resolveOk, statusSol
    end

    function makeFeasible(instance::Problem)
        """
            The completed instance is transformed into a partially solved instance.
            The partial solution is feasible.
        """
        resetVarValues(instance)                # TODO : we can do this better, we are losing the history
    end
    
    function resetVarValues(instance::Problem)
        """
            All the values of the the non-objective variables are reset. 
        """
        for var in values(instance.variables)
            var.value = undef
        end
    end

    function copySolutionValues(instance_from::Problem, instance_to::Problem)
        """
            Backup of the best results.
            Parameters
                - instance_from: source of the values.
                - instance_to: destination of the values.
        """
        for var in values(instance_from.variables)
            instance_to.variables[var.ID].value = var.value
        end
    end

    function copyIndexDomain(instance_from::Problem, instance_to::Problem)
        """
            Backup of the original index_domain.
            Parameters
                - instance_from: source of the values.
                - instance_to: destination of the values.
        """
        for var in values(instance_from.variables)
            instance_to.variables[var.ID].index_domain = var.index_domain
            instance_to.variables[var.ID].index_domain_lower = var.index_domain_lower
        end
    end

    function test_index_domain(instance_copy::Problem)
        """
            Shows the min and max index_domain.
        """
        
        ##
        max_index_domain = 0
        min_index_domain = Inf
        for var in values(instance_copy.variables)
            if var.index_domain > max_index_domain
                max_index_domain = var.index_domain
            end
            if var.index_domain < min_index_domain
                min_index_domain = var.index_domain
            end
        end

        ids_max = Dict()
        for var in values(instance_copy.variables)
            if !(var.index_domain in keys(ids_max))
                ids_max[var.index_domain] = 1
            else
                ids_max[var.index_domain] += 1
            end
        end

        #println("min_index_domain: ", min_index_domain, ", max_index_domain: ", max_index_domain, ", ids_max: ", ids_max)
        ##
    end
end