using Distributed
@everywhere begin
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")

    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"

    using BenchmarkTools
    using Printf
    using Dates
    using CSV
    using DataFrames
    using SharedArrays

    """Generate range of modified polars for performance uncertainty simulation."""
    function generate_performance_uncertainty_samples(polar, params)
        unc_perf = [Performance(polar, i, 1.0) for i in params]
    end
end

function run_ensemble_weather_varied_performance()
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    start_time = Dates.DateTime(2016, 6, 1, 2, 0, 0)
    n_perfs = 10
    params = [i for i in LinRange(0.9, 1.1, n_perfs)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
    routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
    times = SharedArray{Float64}(10*n_perfs, 5)
    @sync @distributed for i in eachindex(perfs)
        for j=LinRange(0, 9, 10)
            counter = Int(j)*i+1
            times[counter, 1] = i
            times[counter, 2] = j
            for k in eachindex(routes)
                wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data) 
                @show result, sp = route_solve(k, perfs[i], start_time, wisp, widi, wadi, wahi, Int(j))
                times[counter, k+2] = result
            end
        end
    end
    df_res = DataFrame(times)
    name1 = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_unc_weather_results"
    CSV.write(name1, df_res)
end

run_ensemble_weather_varied_performance()