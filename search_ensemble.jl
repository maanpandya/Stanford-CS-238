using Graphs
using ProgressMeter
using DataStructures

include("search_hybrid.jl") 

"""
    ensemble_search(vars, data; num_runs::Int=20, threshold::Float64=0.5, hybrid_options::NamedTuple)

Performs an ensemble of hybrid searches to build a high-confidence graph.
1. Runs 'fast_hybrid_search' 'num_runs' times.
2. Counts the frequency of each edge appearing in the results.
3. Builds a final graph containing only edges that appeared with a frequency >= 'threshold'.
"""
function ensemble_search(vars, data; num_runs::Int=20, threshold::Float64=0.5, hybrid_options::NamedTuple)
    
    n = length(vars)

    edge_counts = DefaultDict{Edge, Int}(0)

    println("Phase 1: Generating ensemble of $num_runs graphs")
    
    # Generate ensemble
    # We create a new progress meter for this phase
    p = Progress(num_runs, "Ensemble Runs: ")
    for i in 1:num_runs
        # We don't need the score here, just the graph structure
        graph, _ = fast_hybrid_search(vars, data; hybrid_options...)
        
        for edge in edges(graph)
            edge_counts[edge] += 1
        end
        next!(p) # Update the progress bar
    end
    println("\nPhase 1 Complete.")

    # Build consensus graph
    println("Phase 2: Building consensus graph with threshold τ = $threshold")
    g_consensus = SimpleDiGraph(n)
    
    for (edge, count) in edge_counts
        confidence = count / num_runs
        if confidence >= threshold
            add_edge!(g_consensus, src(edge), dst(edge))
        end
    end
    println("Phase 2 Complete.")
    
    # Score final graph
    println("Scoring final consensus graph")
    final_score = bayesian_score(vars, g_consensus, data)
    
    return g_consensus, final_score
end