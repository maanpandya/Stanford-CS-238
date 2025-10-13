using Graphs
using Random
using ProgressMeter

include("bayesian_score_calc.jl")

"""
    k2_search(vars, data; orderings=10)

Performs the K2 structure learning algorithm. Since K2 is sensitive to the initial
variable ordering, this function runs the core algorithm 'orderings' times with
different random permutations and returns the best graph found.
"""
function k2_search(vars, data; orderings::Int=10)
    n = length(vars)
    best_overall_graph = SimpleDiGraph(n)
    best_overall_score = bayesian_score(vars, best_overall_graph, data)

    @showprogress "K2 Random Orderings: " for i in 1:orderings
        # Generate a new random ordering for each run
        ordering = randperm(n)
        
        graph, score = k2_single_ordering(vars, data, ordering)
        
        if score > best_overall_score
            best_overall_score = score
            best_overall_graph = graph
        end
    end
    
    return best_overall_graph, best_overall_score
end


"""
    k2_single_ordering(vars, data, ordering)

Executes the core K2 algorithm for a single, fixed variable ordering.
"""
function k2_single_ordering(vars, data, ordering::Vector{Int})
    n = length(vars)
    g = SimpleDiGraph(n)
    
    # Start with the score of an empty graph
    # This score is updated incrementally, which is much faster than re-calculating from scratch.
    current_score = bayesian_score(vars, g, data)

    for k in 1:n
        i = ordering[k] # The current node to consider adding parents to
        
        # The set of potential parents are nodes that precede 'i' in the ordering
        potential_parents = if k > 1
            ordering[1:k-1]
        else
            []
        end
        
        # Greedily add parents to node 'i' until score no longer improves
        while true
            best_parent_to_add = 0
            best_score_increase = 0.0
            
            # Find the single best parent to add from the potential set
            for p in potential_parents
                # A node cannot be its own parent, and we only add edges not already present
                if i != p && !has_edge(g, p, i)
                    add_edge!(g, p, i)
                    
                    # Calculate the new score
                    new_score = bayesian_score(vars, g, data)
                    score_increase = new_score - current_score
                    
                    if score_increase > best_score_increase
                        best_score_increase = score_increase
                        best_parent_to_add = p
                    end
                    
                    # Backtrack: remove the edge to test the next parent
                    rem_edge!(g, p, i)
                end
            end
            
            # If we found a parent that improves the score, add it permanently
            if best_parent_to_add != 0
                add_edge!(g, best_parent_to_add, i)
                current_score += best_score_increase
            else
                # No parent addition improves the score, so we are done with node 'i'
                break
            end
        end # end while
    end # end for
    
    return g, current_score
end