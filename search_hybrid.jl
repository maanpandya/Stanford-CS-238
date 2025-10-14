using Graphs
using Random
using ProgressMeter

include("bayesian_score_calc.jl")

"""
    mutual_information(data::Matrix{Int}, i::Int, j::Int, r_i::Int, r_j::Int)

Calculates the mutual information I(X_i; X_j) from the data matrix.
"""
#NOTE: AI HELPED WITH THIS FUNCTION
function mutual_information(data::Matrix{Int}, i::Int, j::Int, r_i::Int, r_j::Int)
    num_samples = size(data, 2)
    
    # Calculate joint and marginal counts
    p_ij = zeros(r_i, r_j)
    p_i = zeros(r_i)
    p_j = zeros(r_j)

    for sample_idx in 1:num_samples
        val_i = data[i, sample_idx]
        val_j = data[j, sample_idx]
        p_ij[val_i, val_j] += 1
        p_i[val_i] += 1
        p_j[val_j] += 1
    end

    # Normalize counts to probabilities
    p_ij ./= num_samples
    p_i ./= num_samples
    p_j ./= num_samples

    mi = 0.0
    for val_i in 1:r_i
        for val_j in 1:r_j
            if p_ij[val_i, val_j] > 1e-9 # Avoid log(0)
                # I(X;Y) = sum_{x,y} P(x,y) * log( P(x,y) / (P(x)P(y)) )
                mi += p_ij[val_i, val_j] * log(p_ij[val_i, val_j] / (p_i[val_i] * p_j[val_j]))
            end
        end
    end
    return mi
end


"""
    fast_hybrid_search(vars, data; max_parents::Int=5)

A hybrid algorithm for large graphs.
1. RESTRICT: Uses mutual information to find a small set of candidate parents for each node.
2. MAXIMIZE: Uses a K2-like greedy search over only the candidate parents.
"""
function fast_hybrid_search(vars, data; max_parents::Int=5)
    n = length(vars)
    g = SimpleDiGraph(n)
    
    # RESTRICT phase
    println("Phase 1: Calculating Mutual Information to find candidate parents")
    candidate_parents = Vector{Vector{Int}}(undef, n)
    
    @showprogress "Finding candidates: " for i in 1:n
        mi_scores = []
        for j in 1:n
            if i == j continue end
            # We need the number of possible values (r) for each variable
            r_i = vars[i].r
            r_j = vars[j].r
            mi = mutual_information(data, i, j, r_i, r_j)
            push!(mi_scores, (j, mi))
        end
        
        # Sort by MI score in descending order
        sort!(mi_scores, by=x->x[2], rev=true)
        
        # Keep the top 'max_parents' candidates
        num_candidates = min(max_parents, length(mi_scores))
        candidate_parents[i] = [p[1] for p in mi_scores[1:num_candidates]]
    end
    println("Phase 1 Complete.")

    # MAXIMIZE phase
    println("Phase 2: Running greedy K2-style search on restricted parent sets")
    current_score = bayesian_score(vars, g, data)

    # We use a random ordering to process the nodes
    node_processing_order = randperm(n)
    
    @showprogress "Greedy search: " for i in node_processing_order
        # Greedily add parents to node 'i' from its candidate set
        while true
            best_parent_to_add = 0
            best_score_increase = 1e-9 # Small positive threshold to ensure meaningful improvement

            for p in candidate_parents[i]
                # Ensure acyclicity by only adding parents that don't create a path back to themselves
                if !has_edge(g, p, i)
                    add_edge!(g, p, i)
                    if !is_cyclic(g)
                        new_score = bayesian_score(vars, g, data)
                        score_increase = new_score - current_score
                        
                        if score_increase > best_score_increase
                            best_score_increase = score_increase
                            best_parent_to_add = p
                        end
                    end
                    rem_edge!(g, p, i) # Backtrack
                end
            end
            
            if best_parent_to_add != 0
                add_edge!(g, best_parent_to_add, i)
                current_score += best_score_increase
            else
                break # No more parents improve the score
            end
        end
    end
    println("Phase 2 Complete.")

    final_score = bayesian_score(vars, g, data)
    return g, final_score
end