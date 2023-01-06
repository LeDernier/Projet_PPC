import .BOperands: Variable
import .LpOperands: LpAffineExpression, LpConstraint, _varMapType
using DataStructures

#export +, -, *,==,>=,<=,!=

## shorten code
varMap(x::Variable) = x

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
function Base.:-(x::Variable, a::Real)
    return x + (-a)
end
function Base.:-(a::Real, x::Variable)
    return a + (-x)
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
# virtual domain : domain defined by the minimal and maximal index_domain

function makeEQ(variable::Variable, constant::Real)
    """
        Modify the virtual domain of x so that x == b, where x is a variable and b is a constant.
        TODO : update this code using Variable.index_domain_lower
    """
    if constant in variable.domain
        # modify the domain and the index_domain so that 'constant' is the...
        # ...only value when iterating over the domain
        minIndex = 1
        indexConstant = findfirst(isequal(constant), variable.domain)
        variable.domain[indexConstant], variable.domain[minIndex] = variable.domain[minIndex], variable.domain[indexConstant]
        variable.index_domain = minIndex

        # assign the value to the variable
        variable.value = constant
    end
end

 function makeLE(variable::Variable, constant::Real)
    """
        Modify the virtual domain of x so that x <= b, where x is a variable and b is a constant.
    """
    if constant in variable.domain
        #variable.domain = sort(variable.domain)             # TODO : need to be sorted ?
        indexConstant = findfirst(isequal(constant), variable.domain)
        variable.index_domain = indexConstant
    end
end

function makeGE(variable::Variable, constant::Real)
    """
        Modify the virtual domain of x so that x <= b, where x is a variable and b is a constant.
    """
    if constant in variable.domain
        #variable.domain = sort(variable.domain)             # TODO : need to be sorted ?
        indexConstant = findfirst(isequal(constant), variable.domain)
        variable.index_domain_lower = indexConstant
    end
end


Base.:(==)(x::Variable, a::Real) = makeEQ(x,float(a))
Base.:(<=)(x::Variable, a::Real) = makeLE(x,float(a))
Base.:(>=)(x::Variable, a::Real) = makeGE(x,float(a))


#= Base.:(==)(x::Variable, y::Variable) = LpConstraint(x - y, 0, ==)
Base.:(<=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, <=)
Base.:(>=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, >=)
Base.:(!=)(x::Variable, y::Variable) = LpConstraint(x - y, 0, !=) =#



Base.:(==)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), ==)
Base.:(<=)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), <=)
Base.:(>=)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), >=)
Base.:(!=)(expr::LpAffineExpression{K,V}, a::Real) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), !=)

Base.:(==)(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), ==)
Base.:(<=)(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), >=)
Base.:(>=)(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), <=)
Base.:(!=)(a::Real, expr::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = LpConstraint(expr, convert(Float64, a), !=)

Base.:(==)(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = expr1 - expr2 == 0.0
Base.:(<=)(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = expr1 - expr2 <= 0.0
Base.:(>=)(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = expr1 - expr2 >= 0.0
Base.:(!=)(expr1::LpAffineExpression{K,V}, expr2::LpAffineExpression{K,V}) where {K<:_varMapType,V<:Real} = expr1 - expr2 != 0.0

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

