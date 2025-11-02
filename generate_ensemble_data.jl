using Graphs
using ProgressMeter
using DataStructures
using JLD2
using Dates

include("search_hybrid.jl")
include("graph_utils.jl")

"""
    accumulate_ensemble_runs(data_file::String, vars, data; num_new_runs::Int, hybrid_options::NamedTuple, dataset_name::String="")

Loads an existing edge_counts dictionary from 'data_file', adds 'num_new_runs' worth of data to it, and saves it back.
Also tracks and saves the best "champion" graph found during the runs.
"""
function accumulate_ensemble_runs(data_file::String, vars, data; num_new_runs::Int, hybrid_options::NamedTuple, dataset_name::String="")

    edge_counts = DefaultDict{Edge, Int}(0)
    total_runs = 0

    if isfile(data_file)
        println("Loading existing ensemble data from $data_file")
        @load data_file edge_counts total_runs
        println("Loaded data from $total_runs previous runs.")
    else
        println("No existing data file found. Starting a new ensemble.")
    end

    println("Starting $num_new_runs new runs to add to the ensemble")
    
    # Track the best graph found in this batch
    champion_graph = nothing
    champion_score = -Inf
    
    p = Progress(num_new_runs, "New Ensemble Runs: ")
    for i in 1:num_new_runs
        graph, score = fast_hybrid_search(vars, data; hybrid_options...)
        for edge in edges(graph)
            edge_counts[edge] += 1
        end
        
        # Check if this is the new champion
        if score > champion_score
            champion_score = score
            champion_graph = graph
        end
        
        next!(p)
    end
    
    total_runs += num_new_runs

    println("\nSaving updated ensemble data to $data_file")
    @save data_file edge_counts total_runs
    println("Successfully saved data for a total of $total_runs runs.")
    
    # Save the champion graph
    if champion_graph !== nothing
        timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
        champion_filename = "ensemble_graphs/$(dataset_name)_champion_$(timestamp)_score_$(round(champion_score, digits=2)).gph"
        write_gph(champion_graph, vars, champion_filename)
        println("\n Champion graph saved to $champion_filename")
        println("   Score: $champion_score")
    end
end


function main_generator()
    println("-"^60)
    println("ENSEMBLE DATA GENERATOR")
    println("-"^60)

    dataset = "large"
    output_file = "large_ensemble_data.jld2"
    
    # Number of runs to perform IN THIS BATCH.
    # You can run this script with 'num_runs_this_batch = 50' multiple times.
    num_runs_this_batch = 50 
    
    hybrid_opts = (max_parents=15,)

    # Run
    csv_path = "data/$dataset.csv"
    vars, data = preprocess_data(csv_path)
    
    accumulate_ensemble_runs(output_file, vars, data; num_new_runs=num_runs_this_batch, hybrid_options=hybrid_opts, dataset_name=dataset)
end

main_generator()