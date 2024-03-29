module BOperands

    export Variable, Variables, BConstraint, num_bConstraints, num_dVariables, 
        _varIDType, _varValueType, size_domain

    ### CONSTANTS ###
    const num_bConstraints = Ref(0)
    const num_dVariables = Ref(0)                       # number of dual variables
    const _varIDType = Union{<:Int, <:String}
    const _varValueType = Union{<:Real, <:Tuple, UndefInitializer}
    
    ### VARIABLES ###

    mutable struct Variable
        ID::_varIDType                                                      # variable name
        domain::Vector{<:_varValueType}                                     # domain / set of feasible values
        value::_varValueType                                                # current value
        index_domain::Integer                                               # maximal index to search in the domain
        index_domain_lower::Integer                                         # minimal index to search in the domain
        primal_vars_ids::Union{UndefInitializer, <:Tuple}       # ids of primal variables/variables in the constraint (if a dual variable)
        nb_constraints::Integer

        function Variable(ID::_varIDType , domain::Vector{<:_varValueType}, 
                        value::_varValueType=undef)
            """
                Constructor of a variable identified by its name.
            """
            #domain = [convert(Float64, val) for val in domain]
            index_domain = init_index_domain(domain)
            return new(ID, domain, value, index_domain, 1, undef, 0)
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

    #Base.show(io::IO, x::Variable) = print(io, string(x.ID)*": "*string(x.domain))
    Base.show(io::IO, x::Variable) = print(io, string(x.ID))

    function size_domain(variable::Variable)
        return variable.index_domain - variable.index_domain_lower
    end

    ### CONSTRAINTS ###

    mutable struct BConstraint
        """
            Explicit binary constraint.
        """
        ID::String
        varsIDs::Vector{<:Union{String,Int,Tuple}}       # variable names
        feasible_points::Vector{Tuple{<:Union{<:Real, <:Tuple}, <:Union{<:Real, <:Tuple}}}
        min_feasible_point::Tuple           # TODO: may not be useful in solver, to remove ?
        max_feasible_point::Tuple           # TODO: may not be useful in solver, to remove ?

        function BConstraint(varsIDs::Vector{<:Union{String,Int,Tuple}}, 
                            feasible_points::Vector{<:Tuple})
            """
                Constructor of an unnamed constraint.
            """
            num_bConstraints[] += 1
            #name = "bC_"*string(num_bConstraints[])         # bC := binary constraint
            varID1 = replace(string(varsIDs[1]), "_" => "")
            varID2 = replace(string(varsIDs[2]), "_" => "")
            name = "bC_"*varID1*"_"*varID2

            feasible_points = sort(feasible_points)
            return new(name, varsIDs, feasible_points, first(feasible_points), last(feasible_points))
        end

        function BConstraint(name::String, varsIDs::Vector{<:Union{String,Int,Tuple}}, 
                            feasible_points::Vector{<:Tuple})
            """
                Constructor of a named constraint.
            """
            #= varID1 = replace(string(varsIDs[1]), "_" => "")  #TODO: remove this since intersect_constraints() failed in solver
            varID2 = replace(string(varsIDs[2]), "_" => "")
            name = "bC_"*varID1*"_"*varID2*"_"*name =#
            
            feasible_points = sort(feasible_points)
            return new(name, varsIDs, sort(feasible_points), first(feasible_points), last(feasible_points))
        end
    end
    
    Base.show(io::IO, c::BConstraint) = print(io, reprBConstraint(c))

    function reprBConstraint(c::BConstraint)
        #repr = "BConstraint(name="*string(c.ID)*"; variables: "*string(c.varsIDs)*"; values=\n"*string(c.feasible_points)*"\n)"
        repr = "BConstraint(name="*string(c.ID)*"; variables: "*string(c.varsIDs)*")"
        return repr
    end
end
