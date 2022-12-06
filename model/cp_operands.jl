module BOperands

    export Variable,Variables, BConstraint, num_bConstraints

    ### CONSTANTS ###
    const num_bConstraints = Ref(0)
    
    ### VARIABLES ###

    mutable struct Variable
        ID::Union{<:Int,<:String}                                # variable name
        domain::Vector{<:Real}                      # domain / set of feasible values
        value::Union{<:Real,UndefInitializer}       # current value
        index_domain::Integer                       # maximal index to search in the domain

        function Variable(ID::Union{<:Int,<:String} , domain::Vector{<:Real}, value::Union{<:Real,UndefInitializer})
            """
                Constructor of a variable identified by its name.
            """
            index_domain = init_index_domain(domain)
            return new(ID, domain, value, index_domain)
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

    Base.show(io::IO, x::Variable) = print(io, string(x.ID))

    ### CONSTRAINTS ###

    mutable struct BConstraint
        """
            Explicit binary constraint.
        """
        name::String
        varsnames::Vector{String}       # variable names
        feasible_points::Vector{Tuple{<:Real, <:Real}}

        function BConstraint(varsnames::Vector{String}, feasible_points::Vector{<:Tuple})
            num_bConstraints[] += 1
            name = "bC_"*string(num_bConstraints[])         # bC := binary constraint
            return new(name, varsnames, feasible_points)
        end
    end

    ## LIST OF VARIABLES ##

    mutable struct Variables
        array::Vector{Variable}
        function Variables(name::String, indices::Vector{Int}, domain::Vector{<:Real}, value::Union{<:Real,UndefInitializer})
            """
                Constructor of an array of variables.
            """
            array = Vector{Variable}()
            
            for index_var in indices
                push!(array, Variable(name, domain, value))
            end

            return new(array)
        end
    end
end
