module LpOperands
    using DataStructures
    using ..BOperands: Variable

    export LpAffineExpression, LpConstraint, num_lpConstraints, value, _varMapType
    
    ## GLOBAL VARIABLES OF THIS MODEL ##
    const num_lpConstraints = Ref(0)
    const _varMapType = Union{String,Int,Variable}      # type use as a key in the linear expressions

    ## STRUCTURES ##

    mutable struct LpAffineExpression{VarIDType<:_varMapType, CoefType<:Real}
        """
            Dictionary where the coefficients of the affine expression are the values and the variables are the keys.
        """
        terms::OrderedDict{VarIDType,CoefType}
        constant::CoefType

        function LpAffineExpression(d::OrderedDict{VarIDType,CoefType}) where {VarIDType<:_varMapType, CoefType<:Real}
            """
                Constructor of linear expression: an affine expression whose constant term is zero.
            """
            return new{VarIDType, CoefType}(d, 0)
        end
        function LpAffineExpression(expr::LpAffineExpression{VarIDType,CoefType}, cons::CoefType) where {VarIDType<:_varMapType, CoefType<:Real}
            """
                Constructor of an affine expression from a linear expression and a constant.
            """
            return new{VarIDType, CoefType}(expr.terms, cons)
        end
    end

    mutable struct LpConstraint{K<:_varMapType,V<:Real}
        """
            Expressions that represent a linear constraint
        """
        ID::String
        lhs::LpAffineExpression{K,V}     # right-hand side
        rhs::Real                   # left-hand side
        relation::Union{Function,UnionAll}         # == or <=
        
    function LpConstraint(lhs::LpAffineExpression{K,V}, rhs::Real, relation::Union{Function,UnionAll}) where {K<:_varMapType,V<:Real}
            """
                Constructor of a linear constraint that has the terms in the left-hand side,
                and the constant in the right-hand side.
            """
            num_lpConstraints[] += 1
            name = "lpC_"*string(num_lpConstraints[])     # lpC := linear constraint
            rhs = convert(Float64, rhs) - lhs.constant
            lhs.constant = 0.0
            return new{K,V}(name, lhs, rhs, relation)
        end
    end

    ## String representation ##

    Base.show(io::IO, expr::LpAffineExpression) = print(io, reprExpression(expr))
    Base.show(io::IO, constr::LpConstraint) = print(io, reprConstraint(constr))

    function reprExpression(expr::LpAffineExpression)
        repr = ""       # string representation
        for (varID, varCoef) in expr.terms
            repr *= string(varCoef)*"*"*string(varID)*" + "
        end
        repr *= string(expr.constant)
        repr = replace(repr, "+ -" => "- ")
        repr = replace(repr, "+ 0.0" => "")
        repr = replace(repr, "- 0.0" => "")
        repr = replace(repr, "+ 0" => "")           # TODO : remove it when ensuring only float values
        repr = replace(repr, "- 0" => "")           # TODO : remove it when ensuring only float values
        return repr
    end

    function reprConstraint(constr::LpConstraint)
        return reprExpression(constr.lhs)*string(constr.relation)*" "*string(constr.rhs)
    end

    function value(expr::LpAffineExpression, valueVars::Tuple)
        value = expr.constant
        vars = collect(keys(expr.terms))
        for i in range(1, length(expr.terms))
            coeff = expr.terms[vars[i]]
            value += coeff * valueVars[i]
        end
        return value
    end
end