struct Domain
    varID::Int64
    possibleValues::Vector{Float64}

    function Domain(varID::Int64, possibleValues::Vector{Float64})::Domain
        return new(varID, possibleValues)
    end
end

struct Constraint
    varID1::Int64
    varID2::Int64
    possibleValues::Vector{Tuple{Float64,Float64}}

    function Constraint(varID1::Int64, varID2::Int64, possibleValues::Vector{Tuple{Float64,Float64}})::Constraint
        return new(varID1, varID2, possibleValues)
    end
end

struct Instance
    nbVariables::Int64
    domains::Vector{Domain}
    constraints::Vector{Constraint}

    function Instance(nbVariables::Int64, domains::Vector{Domain}, constraints::Vector{Constraint})::Instance
        return new(nbVariables, domains, constraints)
    end
end