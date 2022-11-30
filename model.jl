### VARIABLES ###
module Model

export Variable, BConstraint, Instance_BCSP, nbConstraints, nbVariables, print_instance

mutable struct Variable{DataType<:Number}
    name::Any                           # variable name
    index::Any                          # index of the variable in the problem instance
    domain::Vector{DataType}            # domain / set of feasible values
    value::Any                          # current value
    index_domain::Integer               # maximal index to search in the domain

    function Variable(name::String, domain::Vector{DataType}, value::Union{DataType,UndefInitializer}) where DataType
        """
            Constructor of a variable identified by his name.
        """
        index_domain = init_index_domain(domain)
        return new{DataType}(name, undef,domain, value, index_domain)
    end

    function Variable(index::Integer, domain::Vector{DataType}, value::Union{DataType,UndefInitializer}) where DataType
        """
            Constructor of a variable identified by his index in the problem instance.
        """
        index_domain = init_index_domain(domain)
        return new{DataType}(Any, index, domain, value, index_domain)
    end
end


function init_index_domain(domain)
    index_domain = 0
    size_domain = length(domain)
    if size_domain > 0
        index_domain = size_domain
    end
    return index_domain
end


### CONSTRAINTS ###

mutable struct BConstraint
    """
        Binary constraint.
    """
    name::String
    variables::Vector{String}       # variable names
    feasible_points::Union{Vector{Tuple{Int64, Int64}}, Vector{Tuple{Float64, Float64}}}

    function BConstraint(name::String, variables::Vector{String}, feasible_points::Union{Vector{Tuple{Int64, Int64}}, Vector{Tuple{Float64, Float64}}})
        return new(name, variables, feasible_points)
    end
end


### INSTANCE OF A PROBLEM ###

mutable struct Instance_BCSP
    """
        Instance of a binary constraint satisfaction problem.
    """
    variables::Vector{Variable}
    constraints::Vector{BConstraint}
end

function nbVariables(instance::Instance_BCSP)
    """
        Returns the number of variables in the instance.
    """
    return length(instance.variables)
end

function nbConstraints(instance::Instance_BCSP)
    """
        Returns the number of constraints in the instance.
    """
    return length(instance.constraints)
end

function print_instance(instance::Instance_BCSP)
    println("Variables:")
    for var in instance.variables
        println(var)
    end
    println("Constraints:")
    for c in instance.constraints
        println(c)
    end
end

end
