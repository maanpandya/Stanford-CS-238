using Graphs
using Printf
using Random

"""
    write_gph(dag::DiGraph, vars::Vector{Variable}, filename::String)

Takes a DiGraph, a vector of Variable structs, and a filename to write the graph in .gph format.
"""
function write_gph(dag::DiGraph, vars::Vector{Variable}, filename::String)
    # Create the directory if it doesn't exist
    dir = dirname(filename)
    if !isempty(dir) && !isdir(dir)
        mkpath(dir)
    end
    
    # Create a mapping from index to name
    idx2names = Dict(i => vars[i].name for i in 1:length(vars))

    open(filename, "w") do io
        for edge in edges(dag)
            @printf(io, "%s,%s\n", idx2names[src(edge)], idx2names[dst(edge)])
        end
    end
end

"""
    random_dag(n::Int)

Generates a random Directed Acyclic Graph with n vertices.
It creates a random permutation of nodes to ensure acyclicity.
"""
function random_dag(n::Int)
    g = SimpleDiGraph(n)
    nodes = randperm(n) # Random permutation ensures no cycles are created
    for i in 1:n
        for j in (i+1):n
            # Add an edge with 50% probability
            if rand() < 0.5
                add_edge!(g, nodes[i], nodes[j])
            end
        end
    end
    return g
end