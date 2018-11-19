include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")
include(ENV["HOME"]*"/sail_route_old/development/polynesian/polynesian_sims_utils.jl")

using BenchmarkTools, Revise


"""Generate weather for shortest path test functions."""
function generate_weather(tws_val, twa_val, cs_val, cd_val,
                          wahi_val, wadi_val, n)
    empty = zeros(2n, 2n, 2n)
    tws = copy(empty)
    twa = copy(empty)
    cs = copy(empty)
    cd = copy(empty)
    wahi = copy(empty)
    wadi = copy(empty)
    for i in eachindex(tws)
        tws[i] = tws_val
        twa[i] = twa_val
        cs[i] = cs_val
        cd[i] = cd_val
        wahi[i] = wahi_val
        wadi[i] = wadi_val
    end
    return tws, twa, cs, cd, wahi, wadi
end


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

"""Check if an array is monotonic. Works for both directions."""
function check_monotonic(array)                                                  
    # u = all(array[i] <= array[i+1] for i in range(1, length=length(array)-1))
    d = all(array[i] => array[i+1] for i in range(1, length=length(array)-1))
    return u
end


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

function discretization_routine_first_loop(route, perf,
                                start_time, 
                                times)
    # calculate the distance between the start and the finish
    d, b = sail_route.haversine(route.lon1, route.lat1, route.lon2, route.lat2)
    d_n_range = [10.0, 5.0, 3.0] # normalized height
    results = []
    gci = []
    extrap = []
    ooc = []
    for i in d_n_range
        min_dist = d*i/100.0
        n = sail_route.calc_nodes(route.lon1, route.lon2, route.lat1, route.lat2, min_dist)
        sim_route = sail_route.Route(route.lon1, route.lon2, route.lat1, route.lat2, n, n)
        lats = LinRange(0.0, 1.0, n)
        lons = LinRange(0.0, 1.0, n)
        grid_lon = [i for i in lons, j in lats]
        grid_lat = [j for i in lons, j in lats]
        tws, twa, cs, cd, wahi, wadi = generate_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, n)
        res = sail_route.route_solve(sim_route, perf,
                                     start_time, 
                                     times, 
                                     grid_lon, 
                                     grid_lat,
                                     tws, twa,
                                     wadi, wahi,
                                     cs, cd)
        @show res[1]
        push!(results, res[1])
    end
    gci = GCI_calc(results[3], results[2], results[1], d_n_range[3], d_n_range[2], d_n_range[1])
    extrap = extrap_value(results[3], results[2], results[1], d_n_range[3], d_n_range[2], d_n_range[1])
    ooc = ooc_value(results[3], results[2], results[1], d_n_range[3], d_n_range[2], d_n_range[1])
    return extrap, gci
end


"""Test discretization routine for sample weather."""
function test_discretization_uniform_weather()
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