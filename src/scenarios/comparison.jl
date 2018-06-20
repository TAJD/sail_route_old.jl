"""
    kantorovich_distance(ν, μ)

Calculate the kantorovich distance between two probability distributions.

Thanks to this [hero] (https://stla.github.io/stlapblog/posts/KantorovichWithJulia.html)

```jldoctest
julia> mu = [1/7, 2/7, 4/7];
julia> nu = [1/4, 1/4, 1/2];
julia> kantorovich_distance(mu, nu)
0.10714285714285714
```
"""
function kantorovich_distance(ν, μ)
    n = length(ν)
    m = Model(optimizer=CbcSolver())
    @variable(m, p[1:n, 1:n] >= 0)
    @objective(m, Min, sum(p[i, j] for i in 1:n for j in 1:n if i != j))
    for k in 1:n
        @constraint(m, sum(p[k, :]) == μ[k])
        @constraint(m, sum(p[:, k]) == ν[k])
    end
    solve(m)
    return getobjectivevalue(m)
end
