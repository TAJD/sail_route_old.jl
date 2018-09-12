using DataFrames
using CSV

perf = Array([0.9,0.910526,0.921053,0.931579,0.942105])

function return_two()
    return rand(), rand()
end

results = [return_two() for i in 1:5]
times = [i[1] for i in results]
unc = [i[2] for i in results]
results = DataFrames(x=perf, y=times, unc)