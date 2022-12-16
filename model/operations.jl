module Operations
    import ..BOperands: Variable, Variables
    import ..LpOperands: LpAffineExpression, LpConstraint, _varMapType
    using DataStructures

    export +, -, *

    ## shorten code
    varMap(x::Variable) = x

    ## OPERATIONS ON A LIST OF VARIABLES ##

    Base.size(a::Variables) = length(a.array)
    Base.getindex(a::Variables, i::Int) = a.array[i]
    Base.setindex!(a::Variables, v, i::Int) = (a.array[i] = v)
    


    ## Operations between variables and constants ##
    function Base.:-(x::Variable)
        return LpAffineExpression(OrderedDict(varMap(x) => -1.0))
    end
    function Base.:+(x::Variable, a::Real)
        constant = convert(Float64, a)
        return LpAffineExpression(LpAffineExpression(OrderedDict(varMap(x) => 1.0)), constant)
    end
    function Base.:+(a::Real, x::Variable)
        constant = convert(Float64, a)
        return LpAffineExpression(LpAffineExpression(OrderedDict(varMap(x) => 1.0)), constant)
    end
    function Base.:+(x::Variable, y::Variable)
        return LpAffineExpression(OrderedDict(varMap(x) => 1.0, varMap(y) => 1.0))
    end
    function Base.:-(x::Variable, y::Variable)
        return x + (-y)
    end
    function Base.:*(a::Real, x::Variable)
        constant = convert(Float64, a)
        return LpAffineExpression(OrderedDict(varMap(x) => constant))
    end
    function Base.:*(x::Variable, a::Real)
        constant = convert(Float64, a)
        return LpAffineExpression(OrderedDict(varMap(x) => constant))
    end


    ## Operations between LpAffineExpressions
    Base.:-(expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = (-1)*LpAffineExpression(expr, expr.constant)
    
    Base.:+(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = addConstantInPlace(expr, a)
    Base.:+(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = addConstantInPlace(expr, a)
    Base.:+(x::Variable, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = addInPlace(expr, LpAffineExpression(OrderedDict(varMap(x) => 1.0)))
    Base.:+(expr::LpAffineExpression{K,V}, x::Variable) where {K<:_varMapType,V<:Real} = addInPlace(expr, LpAffineExpression(OrderedDict(varMap(x) => 1.0)))
    Base.:+(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = addInPlace(expr1, expr2)
    
    Base.:-(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = subInPlace(expr1, expr2)
    Base.:-(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = addConstantInPlace(expr, -a)
    Base.:-(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = addConstantInPlace(expr, -a)
    Base.:-(expr::LpAffineExpression{K,V}, x::Variable) where {K<:_varMapType,V<:Real} = subInPlace(expr, LpAffineExpression(OrderedDict(varMap(x) => -1.0)))
    Base.:-(x::Variable, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = -subInPlace(expr, LpAffineExpression(OrderedDict(varMap(x) => -1.0)))
    Base.:*(expr1::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = mulInPlace(expr1, a)
    Base.:*(a::Real, expr1::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = mulInPlace(expr1, a)

    ## Relational operations (generating a linear constraints)
    #= Base.:(==)(x::Variable, y::Variable) = LpConstraint(x - y, 0, ==)
    Base.:(<=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, <=)
    Base.:(>=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, >=)
    Base.:(!=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, !=) =#
    

    Base.:(==)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), ==)
    Base.:(<=)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), <=)
    Base.:(=>)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), =>)
    Base.:(!=)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), !=)

    function addInPlace(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real}
        """
            Add the second expression to the first one.
        """
        # update the coefficients
        for (_varmap, varCoeff) in expr2.terms
            if haskey(expr1.terms, _varmap)
                expr1.terms[_varmap] += varCoeff
            else
                expr1.terms[_varmap] = varCoeff
            end
        end
        # update the constant
        expr1.constant += expr2.constant

        return expr1
    end

    function addConstantInPlace(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real}
        expr.constant += a
        return expr
    end

    function subInPlace(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real}
        # update the coefficients
        for (_varmap, varCoeff) in expr2.terms
            if haskey(expr1.terms, _varmap)
                expr1.terms[_varmap] -= varCoeff
            else
                expr1.terms[_varmap] = -varCoeff
            end
        end
        # update the constant
        expr1.constant -= expr2.constant

        return expr1
    end

    function mulInPlace(expr::LpAffineExpression, constant::Real)
        # update the coefficients
        for (_varmap, varCoeff) in expr.terms
            expr.terms[_varmap] = constant*varCoeff
        end
        # update the constant
        expr.constant *= constant

        return expr
    end
end