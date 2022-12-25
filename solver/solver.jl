"""
    Algorithms.
"""

module Solver

    #include("../model/instance.jl")                    # this should only be included in the main file
    include("constants.jl")
    
    using ..Instance: Problem, getVariable,addConstraint        # .. because the include(..model/instance.jl) should be done in the file that includes this file
    include("backtrack.jl")

    export backtrack, solve

    function solve(instance::Problem, maxTime::Real=60)
        """
        Parameters
            - instance: problem instance.
            - maxTime: maximum time given to the solver to find the solution.
        """
        resolveOk = false
        solutionStatus = PSolutionNoSolutionFound
        solutionTime = 0.0
    
        delta_time =  time()
    
        ## resolution phase
        if instance.sense == 0
            resolveOk = actualSolveCSP(instance)
            if resolveOk
                solutionStatus = PSolutionSolutionFound
            else
                solutionStatus = PSolutionInfeasible
            end
        else
            resolveOk, solutionStatus = actualSolveCOP(instance, maxTime) 
        end
        
    
        delta_time = time() - delta_time
        status = get(PSolutionToStatus, solutionStatus, 0)
    
        return status, solutionTime
    end

    function actualSolveCSP(instance::Problem)
        """
            Solve an constraint satisfaction problem.
        """
        return backtrack(instance)
    end

    function actualSolveCOP(instance::Problem, maxTime::Real)
        """
        Solve an constraint optimization problem. The objective should always be a Variable.

        Parameters
            - instance: problem instance.
            - maxTime: maximum time given to the solver to find the solution.
        """
        statusSol = PSolutionNoSolutionFound
        init_time = time()
        delta_time = 0.0

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
        while true
            if delta_time >= maxTime
                break
            end

            delta_time = time() - init_time
            instance.objective <= obj_values[middle_idx]            # change the virtual domain of the objective variable
            resolveOk = actualSolveCSP(instance)
            
            
            if resolveOk
                println("resolveOk with middle_idx: ", middle_idx)
                right_idx = middle_idx
                middle_idx=round(Integer, (left_idx+middle_idx)/2)
                if middle_idx == left_idx
                    break
                end
            else
                println("resolveNotOk with middle_idx: ", middle_idx)
                left_idx = middle_idx
                middle_idx=round(Integer, (middle_idx+right_idx)/2)
                if middle_idx == right_idx
                    break
                end
            end
        end

        ## get the instance associated to middle_idx ##
        instance.objective.value = obj_values[middle_idx]
        instance.objective <= obj_values[middle_idx]
        resolveOk = actualSolveCSP(instance)

        if resolveOk
            statusSol == PSolutionOptimal
        else
            statusSol == PSolutionInfeasible
        end
        
        return resolveOk, statusSol
    end
end