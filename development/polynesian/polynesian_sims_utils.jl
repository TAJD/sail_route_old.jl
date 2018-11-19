using Distributed, SharedArrays, CSV, Interpolations


"""Create a custom iterator which breaks up a range based on the processor number"""
function myrange(q::SharedArray) 
    @show idx = indexpids(q)
    if idx == 0 # This worker is not assigned a piece
        return 1:0, 1:0
    end
    nchunks = length(procs(q))
    splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
    1:size(q,1), splits[idx]+1:splits[idx+1]
end


function route_solve_chunk!(results, t_range, p_range, sim_times, perfs,
                            route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    for t in t_range, p in p_range
        output = route_solve(route, perfs[p], sim_times[t], time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
        @show results[t, p] = output[1]
        output = nothing
    end
end


# function discretize_chunk!(results, t_range, p_range, sim_times, perfs, route, 
#                             weather)
#     for t in t_range, p in p_range
#         wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era20_weather(weather)
#         @show sim_times[t]
#         @show perfs[p]
#         output = sail_route.discretization_routine(route, perfs[p], sim_times[t], times, 
#                                                    wisp, widi, wahi, wadi)
#         results[t, p, 1] = output[1] 
#         results[t, p, 2] = output[2] 
#         results[t, p, 3] = output[3] 
#     end
# end


function discretize_chunk!(results, t_range, p_range, sim_times, perfs, route, 
    weather)
    for t in t_range, p in p_range
        # wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era20_weather(weather)
        # output = sail_route.discretization_routine(route, perfs[p], sim_times[t], times, 
        #                         wisp, widi, wahi, wadi)
        results[t, p, 1] = 10.0
        results[t, p, 2] = 10.0
        results[t, p, 3] = 10.0
    end
end

function load_tong()
    path = ENV["HOME"]*"/sail_route_old/development/polynesian/performance/tongiaki_vpp.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Array{Float64}, df)
    tws = Array{Float64}([0.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 14.0, 16.0, 20.0])
    twa = Array{Float64}([0.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0])
    return twa, tws, perf
end


function load_boeckv2()
    path = ENV["HOME"]*"/sail_route_old/development/polynesian/performance/boeck_v2.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Array{Float64}, df)
    tws = Array{Float64}([0.0,5.832037,7.77605,9.720062,11.66407,13.60809,15.5521,17.49611])
    twa = Array{Float64}([0.0, 60.0, 75.0, 90.0, 110.0, 120.0, 150.0, 170.0])
    return twa, tws, perf
end

"""Run discretization error calculation for time dependent weather data."""
function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time,
                               wisp, widi, wadi, wahi)
    route_nodes = Array([calc_nodes(lon1, lon2, lat1, lat2, i) for i in Array([5.0, 10.0, 20.0])])
    results = zeros(length(route_nodes))
    routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
    locs = []
    for i in eachindex(routes)
        @show results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi , wahi)
    end
    gci_fine = GCI_calc(results[1], results[2], results[3],
                        route_nodes[1], route_nodes[2], route_nodes[3])
    return Array([results[1], results[1]*gci_fine])
end


"""Generate the parameters to simulate for all cases of the Polynesian routing simulation."""
function generate_settings()
    start_locations_lat = [-13.917, -21.21]
    start_locations_lon = [-171.75, -175.15]
    finish_locations_lat = [-19.59, -17.53]
    finish_locations_lon = [-158.07, -149.83]
    start_location_names = ["upolu", "tongatapu"]
    finish_location_names = ["atiu", "moorea"]
    boat_performance = [load_tong(), load_boeckv2()]
    boat_performance_names = ["/tongiaki/", "/boeckv2/"]
    t_inc = 12
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 11, 1, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 11, 1, 0, 0, 0)
    weather_times = [t_low, t_high]
    weather_names = ["low", "high"]
    weather_paths = [ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"]
    node_spacing = [40.0, 20.0, 10.0]
    simulation_settings = []
    save_paths = []
    for i in node_spacing
        for j in eachindex(start_location_names)
            for k in eachindex(finish_location_names)
                for l in eachindex(weather_names)
                    for m in eachindex(boat_performance_names)
                        push!(simulation_settings, [i, start_locations_lon[j], finish_locations_lon[k],
                                                    start_locations_lat[j], finish_locations_lat[k],
                                                    weather_paths[l], weather_times[l],
                                                    boat_performance[m]])
                        route_name = start_location_names[j]*"_to_"*finish_location_names[k]
                        path = boat_performance_names[m]*"_routing_"*route_name*"_"*repr(weather_times[l][1])*"_to_"*repr(weather_times[l][end])*"_"*repr(i)*"_nm.txt"
                        push!(save_paths, path)
                    end
                end
            end
        end
    end
    return simulation_settings, save_paths
end


"""Generate the parameters to simulate for all cases of the Polynesian routing simulation where the domain is automatically sized."""
function generate_settings_auto_domain()
    start_locations_lat = [-13.917, -21.21]
    start_locations_lon = [-171.75, -175.15]
    finish_locations_lat = [-19.59, -17.53]
    finish_locations_lon = [-158.07, -149.83]
    start_location_names = ["upolu", "tongatapu"]
    finish_location_names = ["atiu", "moorea"]
    boat_performance = [load_tong(), load_boeckv2()]
    boat_performance_names = ["/tongiaki/", "/boeckv2/"]
    t_inc = 12
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 11, 1, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 11, 1, 0, 0, 0)
    weather_times = [t_low, t_high]
    weather_names = ["low", "high"]
    weather_paths = [ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"]
    simulation_settings = []
    save_paths = []
    for j in eachindex(start_location_names)
        for k in eachindex(finish_location_names)
            for l in eachindex(weather_names)
                for m in eachindex(boat_performance_names)
                    push!(simulation_settings, [start_locations_lon[j], finish_locations_lon[k],
                                                start_locations_lat[j], finish_locations_lat[k],
                                                weather_paths[l], weather_times[l],
                                                boat_performance[m]])
                    route_name = start_location_names[j]*"_to_"*finish_location_names[k]
                    path = boat_performance_names[m]*"_routing_"*route_name*"_"*repr(weather_times[l][1])*"_to_"*repr(weather_times[l][end])*".txt"
                    push!(save_paths, path)
                end
            end
        end
    end
    return simulation_settings, save_paths
end