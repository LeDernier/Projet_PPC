### STANDARD FORMULATION ###

include("../model.jl")
include("../wrapper.jl")
using .Model
using .Wrapper

function nQueensProblem(n::Int64)
    rows = collect(1:n)
    # variable c_i : index of the column occupied by the queen which is on the i-th row
    variables = collect([Variable("c"*string(i), rows, undef)] for i in rows)
    constr_DiffCol = alldiff(variables)
end

nQueensProblem(4)