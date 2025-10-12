using CSV
using DataFrames

# A struct to hold information about each variable, similar to the textbook
struct Variable
    name::Symbol
    r::Int # Number of possible values (cardinality)
end

function preprocess_data(filepath::String)

    df = CSV.read(filepath, DataFrame)
    variable_names = names(df)

    #Number of values for each variable
    num_values = [maximum(df[!, variable]) for variable in variable_names]

    #Create a vector of Variable structs to hold this info
    vars = [Variable(Symbol(variable_names[i]), num_values[i]) for i in eachindex(variable_names)]

    #For later use, it's good to have the data as a Matrix{Int}
    data_matrix = collect(Matrix(df)') # Transpose to get variables in rows, samples in columns
    
    return vars, data_matrix

end

# Example usage
# vars, data = preprocess_data("data/small.csv")
# println(vars)
# println(size(data))

# Output for small.csv:
# Variable[Variable(:age, 3), Variable(:portembarked, 3), Variable(:fare, 3), Variable(:numparentschildren, 3), Variable(:passengerclass, 3), Variable(:sex, 2), Variable(:numsiblings, 3), Variable(:survived, 2)]
# (8, 889)