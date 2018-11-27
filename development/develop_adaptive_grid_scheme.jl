include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")
include(ENV["HOME"]*"/sail_route_old/development/polynesian/polynesian_sims_utils.jl")

using BenchmarkTools, Revise, DataFrames, Test, Printf
using Plots
unicodeplots()


"""Generate constant performance for shortest path test functions."""
function return_performance()
    awa_range = LinRange(0.0, 180, 11)
    aws_range = LinRange(0.0, 20.0, 11)
    speed = zeros(length(awa_range), length(aws_range))
    fill!(speed, 10.0)
    polar = sail_route.setup_perf_interpolation(aws_range, awa_range, speed)
    perf = sail_route.Performance(polar, 1.0, 1.0, nothing)
    return perf
end


"""No discretization error here"""
function test_routine()
    tws, twa, cs, cd, wahi, wadi = sail_route.generate_constant_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 11)
    perf = return_performance()
    lats = LinRange(0.0, 1.0, 11)
    lons = LinRange(0.0, 1.0, 11)
    grid_lon = [i for i in lons, j in lats]
    grid_lat = [j for i in lons, j in lats]
    lat1 = 0.5
    lon1 = 0.0
    lat2 = 0.5
    lon2 = 1.0
    n = 4
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
    vs_can = sail_route.cost_function_canoe(perf, cd[1, 1, 1], cs[1, 1, 1],
                                        twa[1, 1, 1], tws[1, 1, 1],
                                        wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    vs_con = sail_route.cost_function_conventional(perf, cd[1, 1, 1], cs[1, 1, 1],
                                                twa[1, 1, 1], tws[1, 1, 1],
                                                wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    analytical_time = dist/vs_con
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 2, 3, 0, 0)
    at, locs, ets, x_r, y_r = sail_route.route_solve(sample_route,
                                                            perf,
                                                            start_time, 
                                                            times, 
                                                            grid_lon, 
                                                            grid_lat,
                                                            tws, twa,
                                                            wadi, wahi,
                                                            cs, cd)
    @test isapprox(at, analytical_time; atol=0.01)
    return x_r, y_r    
end



function speed_test()
    n_domain = 75
    tws, twa, cs, cd, wahi, wadi = generate_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, n_domain)
    perf = return_performance()
    lats = LinRange(0.0, 1.0, n_domain)
    lons = LinRange(0.0, 1.0, n_domain)
    grid_lon = [i for i in lons, j in lats]
    grid_lat = [j for i in lons, j in lats]
    lat1 = 0.5
    lon1 = 0.0
    lat2 = 0.5
    lon2 = 1.0
    n = 4
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)

    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 2, 3, 0, 0)

    m1 = BenchmarkTools.median(@benchmark sail_route.route_solve(sample_route, perf, start_time, times,
                                                grid_lon, 
                                                grid_lat,
                                                tws, twa,
                                                wadi, wahi,
                                                cs, cd))
    println(m1)
    m2 = BenchmarkTools.median(@benchmark sail_route.route_solve(sample_route, perf, start_time, times,
                                                grid_lon, 
                                                grid_lat,
                                                tws, twa,
                                                wadi, wahi,
                                                cs, cd))
    println(m2)
    println(judge(m1, m2; time_tolerance = 0.0001))
end


function test_inputs_dev_functions()
    perf = return_performance()
    lat1 = 0.5
    lon1 = 0.0
    lat2 = 0.27
    lon2 = 2.0
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, 2, 2)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 2, 3, 0, 0)
end


"""Test discretization routine for real weather"""
function test_real_weather_discretization_routine()
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    sim_route = sail_route.Route(lon1, lon2, lat1, lat2, 80, 80)
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era20_weather(weather_data)
    x, y, wisp_i, widi_i, wadi_i, wahi_i = sail_route.generate_inputs(sim_route, wisp, widi, wadi, wahi)
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 11, 30, 0, 0, 0)
    twa, tws, speeds = load_tong()
    polar = sail_route.setup_perf_interpolation(tws, twa, speeds)
    perf = sail_route.Performance(polar, 1.0, 1.0, nothing)
    @show results = sail_route.poly_discretization_routine(sim_route, perf, start_time, times,
                                                      wisp, widi, wadi, wahi)
end

test_real_weather_discretization_routine()


# test_real_weather_discretization_routine()
function generate_heights(a, b, n=11)
    heights = LinRange(0.1, 1.0, n)
    log_heights = [a*exp(h*log(b/a)) for h in heights]
    # log_heights = [a*]
    # plot(heights, log_heights,w=2)
    return heights, log_heights
end

"""Test discretization routine for sample weather."""
function test_discretization_uniform_weather()
    lat1 = 25.0
    lon1 = -1.0
    lat2 = 25.0
    lon2 = 51.0
    n = 1
    heights, d_n_range = generate_heights(0.1, 5.0, 2)
    @show heights
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
    boat_performance = ENV["HOME"]*"/sail_route_old/src/data/first40_orgi.csv"
    twa, tws, perf = sail_route.load_file(boat_performance)
    polar = sail_route.setup_perf_interpolation(tws, twa, perf)
    perf = sail_route.Performance(polar, 1.0, 1.0, nothing)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 10, 3, 0, 0)
    results = sail_route.constant_weather_discretization_routine(sample_route, perf,
                                                                 start_time, times, d_n_range)
    df = DataFrame(heights=d_n_range, times=results)
    name1 = ENV["HOME"]*"/sail_route_old/development/constant_upwind_discretization_01 to 10.txt"
    CSV.write(name1, df)
    plot()
    # nd_results = results./results[1]  # non dimensionalised by smallest height
    scatter!(log.(d_n_range), log.(results), color = :white)
    title!("Routing time as a function of grid size")
    yaxis!("Voyaging time (hrs)")
    xaxis!("Grid height (%)")
end

# @time test_discretization_uniform_weather()


"""No discretization error here"""
function test_cartesian_routine()
    tws, twa, cs, cd, wahi, wadi = sail_route.generate_constant_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 11)
    n_locs = 10
    perf = return_performance()
    lats = LinRange(0.0, 1.0, n_locs)
    lons = LinRange(0.0, 1.0, n_locs)
    grid_lon = [i for i in lons, j in lats]
    grid_lat = [j for i in lons, j in lats]
    lat1 = 0.5
    lon1 = -0.1
    lat2 = 0.5
    lon2 = 1.1
    dist, bearing = sail_route.euclidean(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n_locs, n_locs)
    vs_can = sail_route.cost_function_canoe(perf, cd[1, 1, 1], cs[1, 1, 1],
                                        twa[1, 1, 1], tws[1, 1, 1],
                                        wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    vs_con = sail_route.cost_function_conventional(perf, cd[1, 1, 1], cs[1, 1, 1],
                                                twa[1, 1, 1], tws[1, 1, 1],
                                                wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    analytical_time = dist/vs_con
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 1, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 12, 2, 3, 0, 0)
    at, locs, ets, x_r, y_r = sail_route.cartesian_route_solve(sample_route,
                                                            perf,
                                                            start_time, 
                                                            times, 
                                                            grid_lon, 
                                                            grid_lat,
                                                            tws, twa,
                                                            wadi, wahi,
                                                            cs, cd)
    @test isapprox(at, analytical_time; atol=0.01)
    plot()
    scatter((locs[:, 1], locs[:, 2]))
    plot!(title = "Time = "*string(at), xlabel = "X (nm)", ylabel = "Y (nm)")
    plot!(xlims = (minimum(lons), maximum(lons)), ylims = (minimum(lons), maximum(lons)))
end


"""No discretization error here"""
function inspect_cartesian_routine(n_locs, tws_v, twa_v)

    boat_performance = ENV["HOME"]*"/sail_route_old/src/data/first40_orgi.csv"
    twa, tws, perf = sail_route.load_file(boat_performance)
    polar = sail_route.setup_perf_interpolation(tws, twa, perf)
    perf = sail_route.Performance(polar, 1.0, 1.0, nothing)
    lats = LinRange(0.0, 600.0, n_locs)
    lons = LinRange(0.0, 600.0, n_locs)
    tws, twa, cs, cd, wahi, wadi = sail_route.generate_constant_weather(tws_v, twa_v, 0.0, 0.0, 0.0, 0.0, n_locs)
    grid_lon = [i for i in lons, j in lats]
    grid_lat = [j for i in lons, j in lats]
    lat1 = 300.0
    lon1 = -1.0
    lat2 = 300.0
    lon2 = 601.0
    dist, bearing = sail_route.euclidean(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n_locs, n_locs)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 2, 3, 0, 0)
    at, locs, ets, x_r, y_r = sail_route.cartesian_route_solve(sample_route,
                                                            perf,
                                                            start_time, 
                                                            times, 
                                                            grid_lon, 
                                                            grid_lat,
                                                            tws, twa,
                                                            wadi, wahi,
                                                            cs, cd)
    # @test isapprox(at, analytical_time; atol=0.01)
    n_width = dist/(n_locs+1)
    return at, locs, grid_lon, grid_lat, n_width
end


function simulate_example_conditions()
    # for loop for wind speed 
    # for loop for wind direction - plot for each wind speed and wind combination (with real boat)
    for tws in [10.0]
        # for twa in LinRange(90.0, 270.0, 2)
        for twa in [45.0, 90.0, 135]
            plot()
            println("$(@sprintf("%.2f", tws[1])) kts, TWA=$(@sprintf("%.2f", twa[1]))")
            # for i = range(61, step=20, 151)
            for i = [31, 51, 71, 91, 111]
                at, locs, lons, lats, n_width = inspect_cartesian_routine(i, tws, twa)
                scatter!((locs[:, 1], locs[:, 2]), label="n_width = $(@sprintf("%.6f", n_width)) nm, vt = $(@sprintf("%.6f", at)) hrs")
                println("n_width = $(@sprintf("%.6f", n_width)) %, vt = $(@sprintf("%.6f", at)) hrs")
                plot!(xlims = (minimum(lons), maximum(lons)), ylims = (minimum(lons), maximum(lons)))
            end
            display(plot!(title="TWS = $(@sprintf("%.2f", tws[1])) kts, TWA=$(@sprintf("%.2f", twa[1])) degrees", xlabel = "X (nm)", ylabel = "Y (nm)"))
        end 
    end
end

# simulate_example_conditions()