using Dates

@testset "Test domain functions" begin
    dist, bearing = sail_route.haversine(-88.67, 36.12, -118.40, 33.94)
    @test dist ≈ 1462.22 atol = 0.01
    @test bearing ≈ 273.662 atol = 0.01
end

"""Generate weather for shortest path test functions."""
function generate_weather(tws_val, twa_val, cs_val, cd_val,
                          wahi_val, wadi_val)
    empty = zeros(11, 11, 10)
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


@testset "Test shortest path functions" begin
    tws, twa, cs, cd, wahi, wadi = generate_weather(10.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    perf = return_performance()
    lats = LinRange(0.0, 1.0, 11)
    lons = LinRange(0.0, 1.0, 11)
    grid_lon = [i for i in lons, j in lats]
    grid_lat = [j for i in lons, j in lats]
    lat1 = 0.5
    lon1 = 0.0
    lat2 = 0.5
    lon2 = 1.0
    n = 11
    dist, bearing = sail_route.haversine(lon1, lat1, lon2, lat2)
    sample_route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
    vs_can = sail_route.cost_function_canoe(perf, cd[1, 1, 1], cs[1, 1, 1],
                                        twa[1, 1, 1], tws[1, 1, 1],
                                        wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    vs_con = sail_route.cost_function_conventional(perf, cd[1, 1, 1], cs[1, 1, 1],
                                                   twa[1, 1, 1], tws[1, 1, 1],
                                                   wadi[1, 1, 1], wahi[1, 1, 1], bearing)
    @test vs_can ≈ 10.0 atol = 0.01 # canoe cost function 
    @test vs_con ≈ 10.0 atol = 0.01 # conventional cost function 
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
    @test analytical_time ≈ at atol = 0.01
end