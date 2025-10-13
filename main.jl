using DataFrames
using CSV
using Printf

include("data_processing.jl")
include("graph_utils.jl")
include("search_local.jl")
# include("search_k2.jl")
# include("search_simulated_annealing.jl")

"""
    log_score(score_file, dataset, method, score, duration, options)

Logs the results of an experiment to a CSV file.
If an entry for the same (dataset, method, options) combination exists, it's updated.
Otherwise, a new row is added.
"""
function log_score(score_file::String, dataset::String, method::String, score::Float64, duration::Float64, options::NamedTuple)
    
    log_entry = DataFrame(
        dataset=dataset, 
        method=method, 
        options=string(options), 
        score=score, 
        duration=duration
    )

    df = if isfile(score_file)
        CSV.read(score_file, DataFrame)
    else
        # If file doesn't exist, create an empty DataFrame with the correct types
        DataFrame(
            dataset=String[], 
            method=String[], 
            options=String[], 
            score=Float64[], 
            duration=Float64[]
        )
    end

    # Check if a matching entry already exists
    existing_row_idx = findfirst(
        r -> r.dataset == dataset && r.method == method && r.options == string(options),
        eachrow(df)
    )

    if isnothing(existing_row_idx)
        # Append the new result
        append!(df, log_entry)
        println("Logging new result to $score_file.")
    else
        # Update the existing result if the new score is better
        if score > df[existing_row_idx, :score]
            df[existing_row_idx, :] = log_entry[1, :]
            println("Updating with better score in $score_file.")
        else
            println("Keeping existing, better score in $score_file.")
        end
    end

    CSV.write(score_file, df)
end


function run_experiment(dataset_name::String, algorithm::Function, options::NamedTuple)
    println("-"^60)
    println("STARTING EXPERIMENT")
    println("Dataset: $dataset_name")
    println("Algorithm: $(nameof(algorithm))")
    println("Options: $options")
    println("-"^60)

    # 1. Load Data
    csv_path = "data/$dataset_name.csv"
    vars, data = preprocess_data(csv_path)
    
    # 2. Run the search algorithm
    start_time = time()
    best_graph, best_score = algorithm(vars, data; options...)
    end_time = time()
    
    duration = end_time - start_time
    
    # 3. Save the resulting graph
    output_filename = "saved_graphs/$(dataset_name)_$(nameof(algorithm)).gph"
    write_gph(best_graph, vars, output_filename)

    # 4. Log the score to the CSV file
    log_score("scores.csv", dataset_name, string(nameof(algorithm)), best_score, duration, options)

    # 5. Report results to console
    println("\n" * "-"^60)
    println("EXPERIMENT COMPLETE")
    println("Final Score: $best_score")
    println("Graph saved to: $output_filename")
    @printf("Total time: %.2f seconds\n", duration)
    println("-"^60)
end

function main()

    dataset = "small" 
    algo = local_search
    opts = (restarts=5,) 

    run_experiment(dataset, algo, opts)
end

main()