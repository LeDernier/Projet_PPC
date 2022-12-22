using ..Instance: Problem, Variable, addConstraint, addConstraints, BConstraint
using ..Wrapper: all_different

function gracefullGraph(n::Int)::Problem
    # see https://www.csplib.org/Problems/prob053/
    # we focus on wheel graphs

    # create the variables
    node_variables = Vector{Variable}()
    edge_variables = Vector{Variable}()
    center_edge_variables = Vector{Variable}()
    
    node_0 = Variable("node 0", collect(0:2*n), undef)
    push!(node_variables, node_0)

    for i in 1:n
        node_i = Variable("node $i", collect(0:2*n), undef)
        push!(node_variables, node_i)
        edge_i = Variable("edge $i", collect(0:2*n), undef)
        push!(edge_variables, edge_i)
        center_edge_i = Variable("center edge $i", collect(0:2*n), undef)
        push!(center_edge_variables, center_edge_i)
    end

    # create the instance
    instance = Problem()
    instance.addVariables(node_variables)
    instance.addVariables(edge_variables)
    instance.addVariables(center_edge_variables)

    # add the constraints
    addConstraints(instance, all_different(node_variables))
    addConstraints(instance, all_different([edge_variables; center_edge_variables]))
    for i in 1:n
        j = ifelse(i == n, 1, i+1)
        addConstraint(instance, edge_variables[i] == abs(node_variables[i] - node_variables[j]))
        addConstraint(instance, center_edge_variables[i] == abs(node_variables[i] - node_variables[0]))  
        # will it work ?
    end

    return instance
end