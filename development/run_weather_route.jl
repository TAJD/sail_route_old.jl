
using Distributed
@everywhere begin
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")

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

    # """Run discretization error calculation for time dependent weather data."""
    function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time,
                                   wisp, widi, wadi, wahi, ens_number)
        route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
        results = zeros(length(route_nodes))
        routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
        locs = []
        for i in eachindex(routes)
            results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi , wahi, ens_number)
        end
        gci_fine = GCI_calc(results[1], results[2], results[3],
                            route_nodes[1], route_nodes[2], route_nodes[3])
        return Array([results[1], results[1]*gci_fine])
    end
end



function run_ensemble_weather_scenarios()
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    n = 10 # won't interpolate well below 20 nodes
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    
    times = SharedArray{Float64}(10, 2)
    # @sync @distributed for i = 1:10
    for i = 1
        wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
        results = route_solve(sample_route, sample_perf, start_time,
                              wisp, widi, wadi, wahi, Int(i-1))
        @show arrival_time = results[1]
        route = results[2]
        name = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_ens_number_"*repr(Int(i))*"_nodes_"*repr(n)*"_date_"*repr(start_time)
        CSV.write(name, DataFrame(results[2]))
        times[i, :] = Array([Float64(i), results[1]])
    end
    @show df_res = DataFrame(times)
    name1 = ENV["HOME"]*"/sail_route.jl/development/sensitivity/route_ens_results_nodes_"*repr(n)*"_date_"*repr(start_time)
    CSV.write(name1, df_res)
end


run_ensemble_weather_scenarios()

function run_varied_performance()
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    ens_number = 0
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    time = Dates.DateTime(2016, 6, 1, 2, 0, 0)
    n_perfs = 10
    params = [i for i in LinRange(0.9, 1.1, n_perfs)]
    perfs = generate_performance_uncertainty_samples(polar, params)
     # create seperate instance bas
    results = SharedArray{Float64}(length(perfs), 2)
    # @sync @distributed for i in eachindex(perfs)
    for i = 1
        wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
        @show results[i, :] = disc_routing_analysis(lon2, lon1, lat2, lat1, perfs[i], time,
                                                    wisp, widi, wadi, wahi, ens_number)
    end
    times = results[:, 1]
    unc = results[:, 2]
    @show df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/sensitivity/results_"*time
    CSV.write(save_path, df)
end

# run_varied_performance()