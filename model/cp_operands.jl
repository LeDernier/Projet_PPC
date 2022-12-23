module BOperands

    export Variable, Variables, BConstraint, num_bConstraints

    ### CONSTANTS ###
    const num_bConstraints = Ref(0)
    
    ### VARIABLES ###

    mutable struct Variable
        ID::Union{<:Int,<:String}                                # variable name
        domain::Vector{<:Real}                      # domain / set of feasible values
        value::Union{<:Real,UndefInitializer}       # current value
        index_domain::Integer                       # maximal index to search in the domain
        index_domain_lower::Integer                 # minimal index to search in the domain

        function Variable(ID::Union{<:Int,<:String} , domain::Vector{<:Real}, value::Union{<:Real,UndefInitializer}=undef)
            """
                Constructor of a variable identified by its name.
            """
            domain = [convert(Float64, val) for val in domain]
            index_domain = init_index_domain(domain)
            return new(ID, domain, value, index_domain, 1)
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
        varsIDs::Vector{<:Union{String,Int}}       # variable names
        feasible_points::Vector{Tuple{<:Real, <:Real}}

        function BConstraint(varsIDs::Vector{String}, feasible_points::Vector{<:Tuple})
            """
                Constructor of an unnamed constraint.
            """
            num_bConstraints[] += 1
            name = "bC_"*string(num_bConstraints[])         # bC := binary constraint
            return new(name, varsIDs, feasible_points)
        end

        function BConstraint(name::String, varsIDs::Vector{String}, feasible_points::Vector{<:Tuple})
            """
                Constructor of a named constraint.
            """
            return new(name, varsIDs, feasible_points)
        end
    end
    
    Base.show(io::IO, c::BConstraint) = print(io, reprBConstraint(c))

    function reprBConstraint(c::BConstraint)
        repr = "BConstraint(name="*string(c.name)*"; variables: "*string(c.varsIDs)*")"
        return repr
    end
end
