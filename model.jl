### VARIABLES ###

mutable struct variable{DataType<:Number}
    name::String
    domain::Vector{DataType}
    value
end

### CONSTRAINTS ###

mutable struct constraint{DataType <: Real}
    name::String
    variables::Vector{String}       # variable names
    feasible_points                 # , type defined in the constructor
    arity::Int32

    function constraint(name::String, variables::Vector{String}, 
        feasible_points::Vector{Any})
        """
            Constructor of a constraint with an empty feasible region.
        """
        @warn "Constraint with an empty feasible region."
        return new{DataType}(name, variables, feasible_points, length(variables))
    end

    function constraint(name::String, variables::Vector{String}, 
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

    function constraint(name::String, variables::Vector{String}, 
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

mutable struct binary_constraint{DataType <: Real}
    name::String
    variables::Vector{String}       # variable names
    feasible_points::Vector{Tuple{DataType, DataType}}

end

function arity(constraint)
    return length(constraint.variables)
end

x = variable("x", collect(0:5), undef)
x = variable("y", collect(0:5), undef)
c1 = constraint("c1", collect(["x", "y"]), collect([(0,0), (0,1), (1,0)]))
println(c1)
c2 = constraint("c2", collect(["x", "y"]), collect(Int64, []))
println(c2)
c3 = constraint("c3", collect(["x", "y"]), collect([1,2,3]))
println(c3)
print("arity: ", arity(c1))