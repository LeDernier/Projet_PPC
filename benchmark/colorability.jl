using ..Instance: Problem, Variable, addConstraint, addConstraints, addObjective, BConstraint
using ..Wrapper: all_different

function colorability_cp(edges::Vector{Tuple}, num_vertices::Integer, chrom_number_u::Variable)::Problem
    """
    Parameters
        path: graph instance in DIMACS standard format, available at: 
        https://mat.gsia.cmu.edu/COLOR/instances.html.
        - chrom_number_u: upper bound of the chromatic number.
    Return
        An instance of the vertex coloring problem modelled as a O-CP 
        (Optimisation Constraint Program)
    """

    ## problem instance
    # create the variables
    color = Vector{Variable}(undef, num_vertices)          # c_i := color of the i-th 
    for v in 1:num_vertices
        color[v] = Variable("color_vertex_"*string(v), collect(1:chrom_number_u.value))
    end

    # create the instance
    instance = Problem(color)

    # add the objective
    objective = chrom_number_u
    addObjective(instance, objective)

    # add the constraints
    for edge in edges
        adjacent_v = [color[edge[1]],color[edge[2]]]            # adjacent vertices don't have the same color
        addConstraints(instance, all_different(adjacent_v))
    end

    for v in 1:num_vertices
        addConstraint(instance, color[v] - objective <= 0)
    end
    
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

    chrom_number_u,_ = findmax(mc_subgraph)

    return chrom_number_u
end