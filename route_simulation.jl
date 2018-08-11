include("src/weather/load_weather.jl")
include("src/route/domain.jl")
include("src/route/shortest_path.jl")
include("src/performance/polar.jl")

using BenchmarkTools
using Printf
using Dates


"""Run sample optimal routing with no current."""
function run_sample_simulation()
    path = ENV["HOME"]*"/Documents/sail_route.jl/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(path)
    polar = setup_interpolation(tws, twa, perf)
    lon1 = 0.0
    lon2 = 1.0
    lat1 = 5.0
    lat2 = 5.0
    d_an, b_an = haversine(lon1, lat1, lon2, lat2)
    time_an = d_an/perf_interp(polar, min_angle(0.0, 90.0), 10.0)
    d_an_str = @sprintf("%0.2f", d_an)
    b_an_str = @sprintf("%0.2f", b_an)
    t_an_str = @sprintf("%0.2f", time_an)
    println("Analytical distance is $d_an_str nm")
    println("Analytical bearing is $b_an_str deg")
    println("Analytical time is $t_an_str hrs")
    start = Dates.DateTime(2000, 1, 1, 0, 0, 0)
    println("Start time ", start)
    x_nodes = 5
    y_nodes = 5
    y_dist = 100.0
    wisp, widi, cusp, cudi = sample_weather()
    st, ets = route_solve(lon1, lon2, lat1, lat2, x_nodes, y_nodes, y_dist, wisp, widi, cusp, cudi, polar, start)
    t_est_str = @sprintf("%0.2f", st)
    println("Estimated time: ", t_est_str, " hrs")
    if isapprox(st, time_an; rtol=0.000001) == false
        println("failed")
    else
        println("passed")
    end
end


run_sample_simulation()