include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")
include(ENV["HOME"]*"/sail_route_old/development/polynesian/polynesian_sims_utils.jl")

using BenchmarkTools, Revise
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

# """Check if an array is monotonic. Works for both directions."""
# function check_monotonic(array)                                                  
#     # u = all(array[i] <= array[i+1] for i in range(1, length=length(array)-1))
#     d = all(array[i] => array[i+1] for i in range(1, length=length(array)-1))
#     return u
# end


"""No discretization error here"""
function test_routine()
    tws, twa, cs, cd, wahi, wadi = generate_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 11)
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
    # @test vs_can ≈ 10.0 atol = 0.01 # canoe cost function 
    # @test vs_con ≈ 10.0 atol = 0.01 # conventional cost function 
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
    @show at
    @show analytical_time
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

# test_real_weather_discretization_routine()
function generate_heights(a, b, n=11)
    heights = LinRange(0.1, 1.0, n)
    log_heights = [a*exp(h*log(b/a)) for h in heights]
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
    heights, d_n_range = generate_heights(5.0, 25.0, 10)
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
    perf = return_performance()
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 10, 3, 0, 0)
    results = sail_route.constant_weather_discretization_routine(sample_route, perf,
                                                                 start_time, times, d_n_range)
    # plot(d_n_range, results)
    plot()
    nd_results = results./results[1]  # non dimensionalised by smallest height
    scatter!(d_n_range, results)
    title!("Routing time as a function of grid size")
    yaxis!("Voyaging time (hrs)",:log10)
    xaxis!("Grid height (%)",:log10)
end

@time test_discretization_uniform_weather()



