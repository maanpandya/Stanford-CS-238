using Graphs

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