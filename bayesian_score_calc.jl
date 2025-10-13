using Graphs
using SpecialFunctions
using LinearAlgebra
include("data_processing.jl")

function sub2ind(siz, x)
    k = vcat(1, cumprod(siz[1:end-1]))
    return dot(k, x .- 1) + 1
end

function statistics(vars, G, D::Matrix{Int})
    n = size(D, 1) # Number of variables. e.g. if the variables are age, portembarked, sex then n = 3
    r = [vars[i].r for i in 1:n] # Number of possible values for each variable. e.g. if the variables are age, portembarked, sex then r = [3, 3, 2]
    q = [prod([r[j] for j in inneighbors(G,i)]) for i in 1:n] # Product of the number of possible values for the parents of each variable. e.g. if the variables are age, portembarked, sex then q = [6, 6, 9]
    M = [zeros(q[i], r[i]) for i in 1:n] # Create a matrix of zeros for each variable. e.g. if the variables are age, portembarked, sex then M = [zeros(6, 3), zeros(6, 3), zeros(9, 2)]
    for o in eachcol(D) # For each column in the data matrix
        for i in 1:n
            k = o[i] # Get the value of the variable in that column (for example, the value of age in the first data point)
            parents = inneighbors(G,i) # Get the parents of the variable
            j = 1
            if !isempty(parents)
                j = sub2ind(r[parents], o[parents]) # Index of the particular combination of parent instances in the matrix of parent instances
            end
            M[i][j,k] += 1.0 # i takes us to the variable, j takes us to the particular combination of parent instances, k takes us to the value of the variable given those parent instances
        end
    end
    return M
end


function prior(vars, G)
    n = length(vars)
    r = [vars[i].r for i in 1:n]
    q = [prod([r[j] for j in inneighbors(G,i)]; init=1) for i in 1:n]
    return [ones(q[i], r[i]) for i in 1:n]
end

function bayesian_score_component(M, α)
    p = sum(loggamma.(α + M))
    p -= sum(loggamma.(α))
    p += sum(loggamma.(sum(α,dims=2)))
    p -= sum(loggamma.(sum(α,dims=2) + sum(M,dims=2)))
    return p
end

function bayesian_score(vars, G, D)
    n = length(vars)
    M = statistics(vars, G, D)
    α = prior(vars, G)
    return sum(bayesian_score_component(M[i], α[i]) for i in 1:n)
end

#EXAMPLE USAGE SECTION


# This function reads a .gph file and builds a Graphs.SimpleDiGraph
# It needs the `vars` array to map variable names to integer indices.
# NOTE: AI was used to help generate this function because I was not able to find a lot of documentation on how to read a .gph file
function read_gph(filepath::String, vars::Vector{Variable})
    n = length(vars)
    g = SimpleDiGraph(n)
    
    # Create a mapping from variable name (Symbol) to its index (Int)
    name_to_index = Dict(vars[i].name => i for i in 1:n)

    for line in eachline(filepath)
        # Skip empty lines
        if isempty(strip(line))
            continue
        end
        
        parts = split(strip(line), ',')
        if length(parts) == 2
            src_name = Symbol(parts[1])
            dst_name = Symbol(parts[2])
            
            # Check if the names are valid variables
            if haskey(name_to_index, src_name) && haskey(name_to_index, dst_name)
                src_idx = name_to_index[src_name]
                dst_idx = name_to_index[dst_name]
                add_edge!(g, src_idx, dst_idx)
            else
                println("Warning: Could not find variables for edge '$line' in the provided var list.")
            end
        else
            println("Warning: Malformed line in .gph file: '$line'")
        end
    end
    return g
end


function main(csv_path::String, gph_path::String)

    # 1. Pre-process the data
    println("1. Processing data from: $csv_path")
    vars, data_matrix = preprocess_data(csv_path)
    println("   - Found $(length(vars)) variables.")
    println("   - Data matrix size is $(size(data_matrix)).")
    println("-"^40)

    # 2. Load the graph structure from the .gph file
    println("2. Loading graph structure from: $gph_path")
    G = read_gph(gph_path, vars)
    println("   - Graph has $(nv(G)) vertices and $(ne(G)) edges.")
    println("-"^40)

    # 3. Calculate the Bayesian score
    println("3. Calculating Bayesian score...")
    score = bayesian_score(vars, G, data_matrix)
    println("="^40)
    
    # 4. Print the final result
    println("FINAL SCORE: $score")
    println("="^40)
end

#main("example/example.csv", "example/example.gph")