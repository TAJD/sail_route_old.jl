using Distributed
@everywhere begin
    # include(ENV["HOME"]*"/sail_route_old/src/weather/load_weather.jl")
    # include(ENV["HOME"]*"/sail_route_old/src/route/domain.jl")
    # include(ENV["HOME"]*"/sail_route_old/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
    include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")
    include(ENV["HOME"]*"/sail_route_old/development/polynesian/polynesian_sims_utils.jl")
    using ParallelDataTransfer
    using BenchmarkTools
    using Printf
    using Dates
    using CSV
    using DataFrames
    using SharedArrays
    # import sail_route


    route_solve_shared_chunk!(results, times, perfs, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi) = route_solve_chunk!(results, myrange(results)..., times, perfs, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)

    """parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2,
                                    weather, times, perf_t, min_dist)
    Parallized routing simulations.
    """
    function parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2,
                                          weather, times, perf_t, min_dist)
        sim_times = [DateTime(t) for t in times]
        twa, tws, perf = perf_t
        @show params = [round(i; digits=2) for i in LinRange(0.50, 1.50, 21)]
        @show polar = sail_route.setup_perf_interpolation(tws, twa, perf)
        wave_resistance_model = sail_route.typical_aerrtsen()
        perfs = sail_route.generate_performance_uncertainty_samples(polar, params, wave_resistance_model)
        results = SharedArray{Float64, 2}(length(sim_times), length(perfs))
        save_path = ENV["HOME"]*"/sail_route_old/development/polynesian"*save_path
        println(save_path)
        @show n = sail_route.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
        wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era20_weather(weather)
        x, y, wisp, widi, wadi, wahi = sail_route.generate_inputs(route, wisp, widi, wadi, wahi)
        dims = size(wisp)
        cusp, cudi = sail_route.return_current_vectors(y, dims[1])
        @sync begin
            @show for p in procs(results)
                @async remotecall_wait(route_solve_shared_chunk!, p, results, times,
                                       perfs, route, time_indexes, x, y,
                                       wisp, widi, wadi, wahi, cusp, cudi)
            end
        end
        _results = DataFrame(results)
        names!(_results, [Symbol(i) for i in params])
        insert!(_results, 1, times, :start_time)
        CSV.write(save_path, _results)
        return _results
    end
end


function test_single_instance()
    weather = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    @everywhere times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 1, 2, 0, 0, 0)
    @everywhere boat = "/tongiaki/"
    @everywhere route_name = "tongatapu_to_atiu"
    @everywhere wave_model = "resistance_direction_"
    @everywhere min_dist = 60.0
    @everywhere lon1 = -171.15
    @everywhere lat1 = -21.21
    @everywhere lon2 = -158.07
    @everywhere lat2 = -19.59
    @everywhere save_path = boat*"_routing_"*route_name*"_"*wave_model*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm.txt"
    @everywhere perf = load_tong()
    results = parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2, weather, times, perf, min_dist)
    println(results[1, 1])
end


"""Run polynesian simulations based on arguments from command line. Two arguments used to set the lower and upper limits of a range to iterate over."""
function run_simulations(i)
    @everywhere settings = generate_colonisation_voyage_settings()
    @everywhere vals = settings[1]
    @everywhere paths = settings[2]
    @everywhere path = paths[i]
    @everywhere s = vals[i]
    parallized_uncertain_routing(path, s[2], s[4], s[3], s[5], s[6], s[7], s[8], s[1])
end

# comment out these lines if running from bash script
if isempty(ARGS) == false
    @show i = parse(Int64, ARGS[1]); sendto(workers(), i=i)
end

# i = 3; sendto(workers(), i=i)

run_simulations(i)