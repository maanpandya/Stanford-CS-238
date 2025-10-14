using DataFrames
using CSV
using Printf

include("data_processing.jl")
include("graph_utils.jl")
include("search_local.jl")
include("search_k2.jl")
include("search_simulated_annealing.jl")
include("search_hybrid.jl")
include("search_ensemble.jl")

"""
    log_score(score_file, dataset, method, score, duration, options) -> Bool

Logs the results of an experiment to a CSV file and returns `true` if the new score
is an improvement over any existing entry, `false` otherwise.
"""
function log_score(score_file::String, dataset::String, method::String, score::Float64, duration::Float64, options::NamedTuple)
    
    is_improvement = false # This will be our return value

    log_entry = DataFrame(
        dataset=[dataset], 
        method=[method], 
        options=[string(options)], 
        score=[score], 
        duration=[duration]
    )

    df = if isfile(score_file)
        CSV.read(score_file, DataFrame, types=Dict(:options => String, :method => String, :dataset => String))
    else
        DataFrame(
            dataset=String[], method=String[], options=String[], 
            score=Float64[], duration=Float64[]
        )
    end

    existing_row_idx = findfirst(
        r -> r.dataset == dataset && r.method == method,
        eachrow(df)
    )

    if isnothing(existing_row_idx)
        append!(df, log_entry)
        println("Logging new result to $score_file.")
        is_improvement = true
    else
        if score > df[existing_row_idx, :score]
            df[existing_row_idx, :] = log_entry[1, :]
            println("Updating with better score in $score_file.")
            is_improvement = true
        else
            println("Keeping existing, better score in $score_file.")
            # is_improvement remains false
        end
    end

    CSV.write(score_file, df)
    return is_improvement
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
    
    # 3. Log the score and check if it was an improvement
    was_improvement = log_score("scores.csv", dataset_name, string(nameof(algorithm)), best_score, duration, options)
    
    # 4. Save the graph ONLY if the score was an improvement
    output_filename = "saved_graphs/$(dataset_name)_$(nameof(algorithm)).gph"
    if was_improvement
        println("New best score achieved. Saving graph to $output_filename")
        write_gph(best_graph, vars, output_filename)
    else
        println("Did not find a better score. Graph file not updated.")
    end

    # 5. Report results to console
    println("\n" * "-"^60)
    println("EXPERIMENT COMPLETE")
    println("Final Score (for this run): $best_score")
    println("Total time: %.2f seconds\n", duration)
    println("-"^60)
end

function main()

    algorithm = "ensemble_search"

    dataset = "large" 

    if algorithm == "simulated_annealing"
        algo = simulated_annealing
        opts = (initial_temp=50.0, min_temp=0.1, cool_rate=0.995, max_iter=10000)
    elseif algorithm == "k2_search"
        algo = k2_search
        opts = (orderings=1,)
    elseif algorithm == "local_search"
        algo = local_search
        opts = (restarts=5,)
    elseif algorithm == "fast_hybrid_search"
        algo = fast_hybrid_search
        opts = (max_parents=10,)
    elseif algorithm == "ensemble_search"
        algo = ensemble_search
        opts = (num_runs=20, threshold=0.3, hybrid_options=(max_parents=5,))
    end

    run_experiment(dataset, algo, opts)
end

main()