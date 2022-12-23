using ..Instance: Problem, Variable, addConstraint, addConstraints, addObjective, BConstraint
using ..Wrapper: all_different

function colorability_cp(path::String)::Problem
    """
    Parameters
        path: graph instance in DIMACS standard format, available at: 
        https://mat.gsia.cmu.edu/COLOR/instances.html.
    Return
        An instance of the vertex coloring problem modelled as a O-CP 
        (Optimisation Constraint Program)
    """

    edges, num_vertices, num_edges = getEdges(path)
    max_colors = getMaxColors(edges, num_vertices)

    ## problem instance
    # create the variables
    color = Vector{Variable}(undef, num_vertices)          # c_i := color of the i-th 
    for v in 1:num_vertices
        color[v] = Variable("color_vertex_"*string(v), collect(1:max_colors), undef)
    end

    # create the instance
    instance = Problem(color)

    # add the constraints
    for edge in edges
        adjacent_v = [color[edge[1]],color[edge[2]]]        # adjacent vertices
        addConstraints(instance, all_different(adjacent_v))
    end

    # add the objective
    objective = color[1]
    for v in 2:num_vertices
        objective = objective + color[v]
    end
    addObjective(instance, objective)

    return instance
end

function getEdges(path::String)
    """
    Parameters
        path: graph instance in DIMACS standard format, available at: 
        https://mat.gsia.cmu.edu/COLOR/instances.html.
    Return
        a tuple with the list of edges, the number of vertices and the number of edges
    """
    f = open(path)
    data = readlines(f)

    edges = Vector{Tuple}()
    num_vertices = nothing
    num_edges = nothing

    for line in data
        line = split(line," ")                  # line elements
        if line[1] == "p"
            num_vertices = parse(Int64, line[3])
            num_edges = parse(Int64, line[4])                 
        end
        if line[1] == "e"
            v1 = parse(Int64,line[2])           # vertex 1
            v2 = parse(Int64,line[3])           # vertex 2
            push!(edges,(v1,v2))
        end
    end
    close(f)

    return edges, num_vertices, num_edges
end


function getMaxColors(edges::Vector{Tuple}, num_vertices::Integer)
    """
    Returns
        An upper bound for the chromatic number according to:
            Bondy, J. A. (1969). Bounds for the chromatic number 
            of a graph. Journal of Combinatorial Theory, 7(1), 96-98.
    """

    ## upper bound on the number of colors
    
    degrees = zeros(Integer, num_vertices)
    for edge in edges
        degrees[edge[1]] += 1
        degrees[edge[2]] += 1
    end

    mc_subgraph = zeros(Integer, num_vertices)                    # upper bound for the chromatic number of the subgraph 1:vertex
    for vertex in 1:num_vertices
        mc_subgraph[vertex] = min(degrees[vertex]+1, vertex)
    end

    max_colors,_ = findmax(mc_subgraph)

    return max_colors
end