using Distributed, SharedArrays, CSV, Interpolations

function calc_polars(x, y)
    r = sqrt(x^2 + y^2)
    if r == 0.0
        return 0.0, Inf
    elseif x < 0.0 || y > 0.0
        theta = acosd(x/r) + 180.0
    elseif y > 0.0
        theta = acosd(x/r) 
    elseif y == 0.0
        theta = acosd(x/r) + 90.0
    elseif y < 0.0
        theta = -acosd(x/r) - 90.0
    end
    return r, abs(theta)
end

"""Load current data for mid Pacific."""
function load_current_data()
    path = ENV["HOME"]*"/sail_route.jl/development/polynesian/current_data/"
    m_path = path*"meridional.csv"
    z_path = path*"zonal.csv"
    meridional = convert(Array{Float64}, CSV.read(m_path, delim=',', datarow=1))
    zonal = convert(Array{Float64}, CSV.read(z_path, delim=',', datarow=1))
    meridional[:, 1] *= (0.01*1.9438444924406)
    zonal[:, 1] *= (0.01*1.9438444924406)
    meridional = meridional[end:-1:1, :]
    zonal = zonal[end:-1:1, :]
    merid_interp = interpolate((meridional[:, 2],), meridional[:, 1], Gridded(Linear()))
    merid = extrapolate(merid_interp, Line())  
    zonal_interp = interpolate((zonal[:, 2],), zonal[:, 1], Gridded(Linear()))
    zonal = extrapolate(zonal_interp, Line())  
    lats = collect(LinRange(-25, 25, 80))
    merid_sp = merid.(lats)
    zonal_sp = zonal.(lats)
    r = zeros(size(lats))
    theta = zeros(size(lats))
    r = [calc_polars(merid_sp[i], zonal_sp[i])[1] for i in eachindex(lats)]
    theta = [calc_polars(merid_sp[i], zonal_sp[i])[2] for i in eachindex(lats)]
    r_interp = interpolate((lats,), r, Gridded(Linear()))
    r_final = extrapolate(r_interp, Line()) 
    theta_interp = interpolate((lats,), theta, Gridded(Linear()))
    theta_final = extrapolate(theta_interp, Line())
    return r_final, theta_final
end

function return_current_vectors(y, t_length)
    cusp = zeros((t_length, size(y)[1], size(y)[2]))
    cudi = zeros((t_length, size(y)[1], size(y)[2]))
    r, theta = load_current_data()
    for i in 1:t_length
        cusp[i, :, :] = r.(y)
        cudi[i, :, :] = theta.(y)
    end
    return cusp, cudi
end


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


function route_solve_upolu_to_atiu!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        output = nothing
    end
    results
end


function route_solve_upolu_to_moorea!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -149.83
    lat2 = -17.53
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end


function route_solve_tongatapu_to_moorea!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -149.83
    lat2 = -17.53
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end



function route_solve_tongatapu_to_atiu!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end


function route_solve_chunk!(results, t_range, p_range, sim_times, perfs,
                            route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    for t in t_range, p in p_range
        output = route_solve(route, perfs[p], sim_times[t], time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
        @show results[t, p] = output[1]
        output = nothing
    end
end



function load_tong()
    path = ENV["HOME"]*"/sail_route.jl/development/polynesian/performance/tongiaki_vpp.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Array{Float64}, df)
    tws = Array{Float64}([0.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 14.0, 16.0, 20.0])
    twa = Array{Float64}([0.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0])
    return twa, tws, perf
end


function load_boeckv2()
    path = ENV["HOME"]*"/sail_route.jl/development/polynesian/performance/boeck_v2.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Array{Float64}, df)
    tws = Array{Float64}([0.0,5.832037,7.77605,9.720062,11.66407,13.60809,15.5521,17.49611])
    twa = Array{Float64}([0.0, 60.0, 75.0, 90.0, 110.0, 120.0, 150.0, 170.0])
    return twa, tws, perf
end


"""Generate range of modified polars for performance uncertainty simulation."""
function generate_performance_uncertainty_samples(polar, params, wave_m)
    unc_perf = [Performance(polar, i, 1.0, wave_m) for i in params]
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
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 2, 1, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 2, 1, 0, 0, 0)
    weather_times = [t_low, t_high]
    weather_names = ["low", "high"]
    weather_paths = [ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"]
    node_spacing = [20.0, 15.0, 10.0]
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
