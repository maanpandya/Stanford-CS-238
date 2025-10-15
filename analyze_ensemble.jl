using Graphs
using JLD2
using Printf

include("bayesian_score_calc.jl")
include("data_processing.jl")
include("graph_utils.jl")

"""
    find_best_threshold(data_file::String, vars, data, thresholds_to_test)

Loads a saved ensemble and tests multiple thresholds to find the best-scoring graph.
"""
function find_best_threshold(data_file::String, vars, data, thresholds_to_test)
    if !isfile(data_file)
        error("Ensemble data file not found: $data_file. Run the generator script first.")
    end
    
    println("Loading ensemble data from $data_file")
    @load data_file edge_counts total_runs
    println("Loaded data from $total_runs total runs.")
    println("-"^60)

    best_score = -Inf
    best_graph = SimpleDiGraph(length(vars))
    best_threshold = 0.0

    println("Testing thresholds")
    @printf("%-12s | %-20s | %-12s\n", "Threshold", "Score", "Edge Count")
    println("-"^50)

    for τ in thresholds_to_test
    # CORRECTED GRAPH CONSTRUCTION

        # Get all candidate edges that are above the current threshold
        candidate_edges = Edge[]
        for (edge, count) in edge_counts
            if (count / total_runs) >= τ
                push!(candidate_edges, edge)
            end
        end

        # Sort these candidate edges by their confidence (count) in descending order.
        # Prioritize the most confident edges.
        sort!(candidate_edges, by=e -> edge_counts[e], rev=true)

        # Build the consensus graph by greedily adding edges, ensuring it remains acyclic.
        g_consensus = SimpleDiGraph(length(vars))
        for edge in candidate_edges
            # Add the edge
            add_edge!(g_consensus, edge)
            # Check if a cycle was introduced.
            if is_cyclic(g_consensus)
                # If so, this edge is invalid in the context of the current graph. Remove it
                rem_edge!(g_consensus, edge)
            end
        end

        # END OF CORRECTIONS

        score = bayesian_score(vars, g_consensus, data)
        @printf("τ = %-7.2f | %-20.4f | %-12d\n", τ, score, ne(g_consensus))

        if score > best_score
            best_score = score
            best_graph = g_consensus
            best_threshold = τ
        end
    end
    
    println("-"^50)
    println("Best threshold found: τ = $best_threshold")
    println("Best score found: $best_score")

    # Save the single best graph for submission
    output_gph_file = "saved_graphs/large_ensemble_BEST.gph"
    println("Saving best graph to $output_gph_file")
    write_gph(best_graph, vars, output_gph_file)
    
    return best_graph, best_score
end


function main_analyzer()
    println("-"^60)
    println("ENSEMBLE ANALYZER")
    println("-"^60)
    
    dataset = "large"
    data_file = "large_ensemble_data.jld2"
    
    # Define the range of confidence thresholds we want to test
    thresholds_to_test = 0:0.005:0.80

    csv_path = "data/$dataset.csv"
    vars, data = preprocess_data(csv_path)

    find_best_threshold(data_file, vars, data, thresholds_to_test)
end

main_analyzer()