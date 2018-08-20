include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"

using BenchmarkTools
using Printf
using Dates


"""Run sample optimal routing with no current."""
function run_sample_simulation()
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 0.0, 1.0, load_env_failure_model())
    sample_route = Route(0.0, 1.0, 5.0, 5.0, 10, 10)
    d_an, b_an = haversine(sample_route.lon1, sample_route.lat1, sample_route.lon2, sample_route.lat2)
    time_an = d_an/perf_interp(polar, min_angle(0.0, 90.0), 10.0)
    d_an_str = @sprintf("%0.2f", d_an)
    b_an_str = @sprintf("%0.2f", b_an)
    t_an_str = @sprintf("%0.5f", time_an)
    println("Analytical distance is $d_an_str nm")
    println("Analytical bearing is $b_an_str deg")
    println("Analytical time is $t_an_str hrs")
    start_time = Dates.DateTime(2000, 1, 1, 0, 0, 0)
    println("Start time ", start_time)
    wisp, widi, cusp, cudi, wahi, wadi = sample_weather()
    st, ets = route_solve(sample_route, sample_perf, start_time, wisp, widi, cusp, cudi, wahi, wadi)
    t_est_str = @sprintf("%0.5f", st)
    println("Estimated time: ", t_est_str, " hrs")
    if isapprox(st, time_an; rtol=0.000001) == false
        println("failed")
    else
        println("passed")
    end
end


run_sample_simulation()