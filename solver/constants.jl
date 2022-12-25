"""
    Constants that define the state of the Constraint Satisfaction Problem (P).
"""


# variable categories
PInteger = "Integer"
PBinary = "Binary"
PCategories = Dict(PInteger => "Integer", PBinary => "Binary")

# objective sense
PMinimize = 1
PSatisfy = 0
PMaximize = -1
PSenses = Dict(
    PMaximize => "Maximize", 
    PSatisfy => "Satisfy",
    PMinimize => "Minimize",
)

# problem status
PStatusNotSolved = 0
PStatusFeasible = 1
PStatusOptimal = 2
PStatusInfeasible = -1
PStatus = Dict(
    PStatusNotSolved => "Not Solved",
    PStatusFeasible => "Feasible",
    PStatusOptimal => "Optimal",
    PStatusInfeasible => "Infeasible",
)

# solution status
PSolutionNoSolutionFound = 0
PSolutionSolutionFound = 1
PSolutionOptimal = 2
PSolutionInfeasible = -1
PSolution = Dict(
    PSolutionNoSolutionFound => "No Solution Found",
    PSolutionSolutionFound => "Solution Found",
    PSolutionOptimal => "Optimal Solution Found",
    PSolutionInfeasible => "No Solution Exists",
)

PSolutionToStatus = Dict(
    PSolutionSolutionFound => PStatusFeasible,
    PSolutionOptimal => PStatusOptimal,
    PSolutionInfeasible => PStatusInfeasible,
)

#= PStatusToSolution = Dict(
    PStatusNotSolved => PSolutionInfeasible,
    PStatusFeasible => PSolutionSolutionFound,
    PStatusOptimal => PSolutionOptimal,
    PStatusInfeasible => PSolutionInfeasible,
) =#