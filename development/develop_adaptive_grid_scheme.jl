include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")

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

perf = return_performance()
lat1 = 0.5
lon1 = 0.0
lat2 = 0.27
lon2 = 2.0
dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
sample_route = sail_route.Route(lon1, lon2, lat1, lat2, 2, 2)
start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
times = Dates.DateTime(2016, 7, 1, 0, 0, 0):Dates.Hour(3):Dates.DateTime(2016, 7, 2, 3, 0, 0)


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

"""For example weather and performance conditions apply the numerical error reduction routine.

1. Iterates over three node distances calculated as a function of percentage of the voyage routes.
2. If it doesn't look like the voyage times are converging due to the order of convergence or the results not monotonically decreasing then the next node distance will be reduced and the simulations will be run again.

To develop this properly need to load the weather files and to interpolate them within each for/while loop."""
function discretization_routine_sample(route, perf,
                        start_time, 
                        times)
    d, b = sail_route.haversine(route.lon1, route.lat1, route.lon2, route.lat2)
    d_n_range = [10.0, 5.0, 3.0] # normalized height
    results = []
    gci = []
    extrap = []
    ooc = []
    for i in d_n_range # Loop 1
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
        push!(results, res[1])
    end
    gci = GCI_calc(results[end], results[end-1], results[end-2],
                   d_n_range[end], d_n_range[end-1], d_n_range[end-2])
    extrap = extrap_value(results[end], results[end-1], results[end-2],
                          d_n_range[end], d_n_range[end-1], d_n_range[end-2])
    ooc = ooc_value(results[end], results[end-1], results[end-2],
                    d_n_range[end], d_n_range[end-1], d_n_range[end-2])
    if ooc > 1.0 && results[end-1] < results[end-2]
        return extrap, gci
    else 
        iterations = 0
        while ooc < 1.0  || results[end-1] > results[end-2] # Loop 2
            if float(iterations) > 4.0
                return extrap, gci
            end
            iterations += 1
            d_n_m = d_n_range[end]/2.0 # calculate next multiple of d_n
            push!(d_n_range, d_n_m)
            min_dist = d*d_n_m/100.0
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
            push!(results, res[1])
            gci = GCI_calc(results[end], results[end-1], results[end-2],
                           d_n_range[end], d_n_range[end-1], d_n_range[end-2])
            extrap = extrap_value(results[end], results[end-1], results[end-2],
                                  d_n_range[end], d_n_range[end-1], d_n_range[end-2])
            ooc = ooc_value(results[end], results[end-1], results[end-2],
                            d_n_range[end], d_n_range[end-1], d_n_range[end-2])
            return extrap, gci
        end
    end
end

# @show discretization_routine_first_loop(sample_route, perf, start_time, times)

@time discretization_routine_sample(sample_route, perf, start_time, times)