using Distributed
@everywhere begin 
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")


    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"

    using BenchmarkTools
    using Printf
    using Dates
    using Distributed
    using DistributedArrays
    using SharedArrays
end


# Solve the route for all weather scenarios (1 to 10) for the discretized error - save as dataframe with the % uncertainty and the weather scenario