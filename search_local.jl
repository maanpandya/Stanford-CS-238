using Graphs
using ProgressMeter

include("bayesian_score_calc.jl")
include("graph_utils.jl")

"""
    get_neighbors(g::SimpleDiGraph)

Generates all valid neighbors of a graph `g` by adding, removing, or reversing a single edge.
A neighbor is valid if it is not the same as `g` and contains no cycles.
"""
function get_neighbors(g::SimpleDiGraph)
    n = nv(g)
    neighbors = SimpleDiGraph[]
    
    for i in 1:n
        for j in 1:n
            if i == j continue end
            
            # 1. Try adding an edge
            if !has_edge(g, i, j)
                g_new = copy(g)
                add_edge!(g_new, i, j)
                if !is_cyclic(g_new)
                    push!(neighbors, g_new)
                end
            else # has_edge(g, i, j) is true
                # 2. Try removing the edge
                g_new_rem = copy(g)
                rem_edge!(g_new_rem, i, j)
                push!(neighbors, g_new_rem)

                # 3. Try reversing the edge
                if !has_edge(g, j, i)
                    g_new_rev = copy(g_new_rem)
                    add_edge!(g_new_rev, j, i)
                    if !is_cyclic(g_new_rev)
                        push!(neighbors, g_new_rev)
                    end
                end
            end
        end
    end
    return neighbors
end

"""
    local_search(vars, data; restarts=10)

Performs local search (hill climbing) to find a high-scoring Bayesian network structure.
"""
function local_search(vars, data; restarts=10)
    n = length(vars)
    best_overall_graph = SimpleDiGraph(n)
    best_overall_score = bayesian_score(vars, best_overall_graph, data)

    # @showprogress macro for the restarts loop
    @showprogress "Local Search Restarts: " for i in 1:restarts
        
        current_graph = random_dag(n)
        current_score = bayesian_score(vars, current_graph, data)
        
        # Inner loop performs the hill-climbing for one restart
        while true
            neighbors = get_neighbors(current_graph)
            if isempty(neighbors)
                break
            end

            neighbor_scores = [bayesian_score(vars, ng, data) for ng in neighbors]
            best_neighbor_score, best_neighbor_idx = findmax(neighbor_scores)

            if best_neighbor_score <= current_score
                # Local optimum reached for this restart
                break
            end
            
            current_score = best_neighbor_score
            current_graph = neighbors[best_neighbor_idx]
        end
        
        if current_score > best_overall_score
            best_overall_score = current_score
            best_overall_graph = current_graph
        end
    end
    
    return best_overall_graph, best_overall_score
end