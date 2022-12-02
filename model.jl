### VARIABLES ###

mutable struct Variable{DataType<:Number}
    name::Any                           # variable name
    index::Int                          # index of the variable in the problem instance
    domain::Vector{DataType}            # domain / set of feasible values
    value::Any                          # current value
    index_domain::Integer               # maximal index to search in the domain

    function Variable(name::String, index::Integer, domain::Vector{DataType}, value::Union{DataType,UndefInitializer}) where DataType
        """
            Constructor of a variable identified by its name and index.
        """
        index_domain = init_index_domain(domain)
        return new{DataType}(name, index, domain, value, index_domain)
    end

#=     function Variable(index::Integer, domain::Vector{DataType}, value::Union{DataType,UndefInitializer}) where DataType
        """
            Constructor of a variable identified by its index in the problem instance.
        """
        index_domain = init_index_domain(domain)
        return new{DataType}(Any, index, domain, value, index_domain)
    end =#
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
    variable_names::Tuple{String, String}      # variable names
    variable_indices::Tuple{Int, Int}
    feasible_points::Union{Vector{Tuple{Int64, Int64}}, Vector{Tuple{Float64, Float64}}}

    function BConstraint(name::String, variable_names::Tuple{String, String}, variable_indices::Tuple{Int, Int}, feasible_points::Union{Vector{Tuple{Int64, Int64}}, Vector{Tuple{Float64, Float64}}})
        return new(name, variable_names, variable_indices, feasible_points)
    end
end

# CONSTRAINT - TODO : remove if not useful in the future

mutable struct Constraint{DataType <: Real}
    name::String
    variables::Vector{String}       # variable names
    feasible_points                 # , type defined in the constructor
    arity::Integer

    function Constraint(name::String, variables::Vector{String}, 
        feasible_points::Vector{Any})
        """
            Constructor of a constraint with an empty feasible region.
        """
        @warn "Constraint with an empty feasible region."
        return new{DataType}(name, variables, feasible_points, length(variables))
    end

    function Constraint(name::String, variables::Vector{String}, 
        feasible_points::Vector{DataType}) where DataType
        """
            Constructor of a constraint on a single variable.
        """
        # checking dimension consistency
        arity = length(variables)
        if arity != 1
            error("The dimension of the feasible points and the number of variable does not match.")
        end
        return new{DataType}(name, variables, feasible_points, arity)
    end

    function Constraint(name::String, variables::Vector{String}, 
        feasible_points::Vector{Tuple{DataType, DataType}}) where DataType
        """
            Constructor of a constraint defined on two or more variable.
        """
        # checking dimension consistency
        arity = length(variables)
        if arity != length(feasible_points[1])
            error("The dimension of the feasible points and the number of variable does not match.")
        end

        return new{DataType}(name, variables, feasible_points, arity)
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

### TESTS ####

x = Variable("x", 1, collect(Float64, 0:5), undef)
y = Variable("y", 2, collect(0:5), undef)

c1 = BConstraint("c1", ("x", "y"), (1, 2), collect([(0,0), (0,1), (1,0)]))
c2 = BConstraint("c2", ("x", "y"), (1, 2), collect([(1,0),(2,1)]))

instance = Instance_BCSP(collect([x,y]),collect([c1,c2]))
print_instance(instance)