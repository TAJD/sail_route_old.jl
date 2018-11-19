using Distributed
@everywhere begin
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

    # change to remove references to the number of nodes
    discretized_shared_chunk!(results, times, perfs, route, weather) = discretize_chunk!(results, myrange(results)..., times, perfs, route, weather)

    """parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2,
                                    weather, times, perf_t)
    Parallized routing simulations.
    """
    function parallized_num_err_uncertain_routing(save_path, lon1, lat1, lon2, lat2,
                                                  weather, times, perf_t)
        sim_times = [DateTime(t) for t in times]
        twa, tws, perf = perf_t
        params = [round(i; digits=2) for i in LinRange(0.50, 1.50, 3)]  # 3 for testing
        polar = sail_route.setup_perf_interpolation(tws, twa, perf)
        wave_resistance_model = sail_route.typical_aerrtsen()
        perfs = sail_route.generate_performance_uncertainty_samples(polar, params,
                                                         wave_resistance_model)
        results = SharedArray{Float64, 3}(length(sim_times), length(perfs), 3)
        save_path = ENV["HOME"]*"/sail_route_old/development/polynesian"*save_path
        println(save_path)
        route = sail_route.Route(lon1, lon2, lat1, lat2, 2, 2)
        @sync begin
            for p in procs(results)
                @async remotecall_wait(discretized_shared_chunk!, p, results,
                                       sim_times,
                                       perfs, route,
                                       weather)
            end
        end
        vts = DataFrame(results[:, :, 1])
        names!(vts, [Symbol(i) for i in params])
        insert!(vts, 1, times, :start_time)
        CSV.write(save_path*"_times.txt", vts)
        @show gcis = DataFrame(results[:, :, 2])
        names!(gcis, [Symbol(i) for i in params])
        insert!(gcis, 1, times, :start_time)
        CSV.write(save_path*"_gci.txt", gcis)
        @show oocs = DataFrame(results[:, :, 2])
        names!(oocs, [Symbol(i) for i in params])
        insert!(oocs, 1, times, :start_time)
        CSV.write(save_path*"_ooc.txt", oocs)
        return vts
    end
end


function test_single_instance()
    weather = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    @everywhere times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 1, 1, 12, 0, 0)
    @everywhere boat = "/tongiaki/"
    @everywhere route_name = "tongatapu_to_atiu"
    @everywhere lon1 = -171.15
    @everywhere lat1 = -21.21
    @everywhere lon2 = -158.07
    @everywhere lat2 = -19.59
    @everywhere save_path = boat*"_routing_"*route_name*"_"*repr(times[1])*"_to_"*repr(times[end])
    @everywhere perf = load_tong()
    results = parallized_num_err_uncertain_routing(save_path, lon1, lat1, lon2, lat2, weather, times, perf)
    println(results[1, 1])
end

# test_single_instance()

"""Run polynesian simulations based on arguments from command line. Two arguments used to set the lower and upper limits of a range to iterate over."""
function run_simulations(i)
    @everywhere settings = generate_settings_auto_domain()
    @everywhere vals = settings[1]
    @everywhere paths = settings[2]
    @everywhere path = paths[i]
    @everywhere s = vals[i]
    @show s
    # parallized_uncertain_routing(path, s[1], s[3], s[2], s[4], s[5], s[6], s[7])
end

if isempty(ARGS) == false
    @show i = parse(Int64, ARGS[1]); sendto(workers(), i=i)
end


run_simulations(1) # set 1 to i for creating job array