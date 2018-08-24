

using Dates

"""Run multiple simulations.

1. Ranges of dates.
1. Save the link to the performance file used
2. Ranges of routes.
3. Run simulations.
4. Save the results to a txt file."""
function save_dataframe()
    # Load simulation functions
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")

    nodes = 160
    east_to_west = Route(-6.486, -59.883, 61.48, -1.76, nodes, nodes)
    west_to_east = Route(-59.883, -6.486,  -1.76, 61.48, nodes, nodes)

    results = rand(2)
    sample_perf = Performance(polar, 1.0, 1.0, 1.0);
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    f_path = ENV["HOME"]*"/sail_route.jl/development/file.txt"
    open(f_path, 'w') do f
        write(f, strftime(time()))
        write(f, results)
    end
end

function save_dataframe()