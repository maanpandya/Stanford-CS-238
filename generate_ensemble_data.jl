using Graphs
using ProgressMeter
using DataStructures
using JLD2

include("search_hybrid.jl")

"""
    accumulate_ensemble_runs(data_file::String, vars, data; num_new_runs::Int, hybrid_options::NamedTuple)

Loads an existing edge_counts dictionary from 'data_file', adds 'num_new_runs' worth of data to it, and saves it back.
"""
function accumulate_ensemble_runs(data_file::String, vars, data; num_new_runs::Int, hybrid_options::NamedTuple)

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
    
    p = Progress(num_new_runs, "New Ensemble Runs: ")
    for i in 1:num_new_runs
        graph, _ = fast_hybrid_search(vars, data; hybrid_options...)
        for edge in edges(graph)
            edge_counts[edge] += 1
        end
        next!(p)
    end
    
    total_runs += num_new_runs

    println("\nSaving updated ensemble data to $data_file")
    @save data_file edge_counts total_runs
    println("Successfully saved data for a total of $total_runs runs.")
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
    
    hybrid_opts = (max_parents=10,)

    # Run
    csv_path = "data/$dataset.csv"
    vars, data = preprocess_data(csv_path)
    
    accumulate_ensemble_runs(output_file, vars, data; num_new_runs=num_runs_this_batch, hybrid_options=hybrid_opts)
end

main_generator()