@testset "Test domain functions" begin
    dist, bearing = sail_route.haversine(-88.67, 36.12, -118.40, 33.94)
    @test dist ≈ 1462.22 atol = 0.01
    @test bearing ≈ 273.662 atol = 0.01
end


# @testset "Test optimum route algorithm" begin
#     path = ENV["HOME"]*"/sail_route.jl/src/data/first40_orgi.csv"
#     twa, tws, perf = load_file(path)
#     polar = sail_route.setup_interpolation(tws, twa, perf)
#     lon1 = 0.0
#     lon2 = 1.0
#     lat1 = 5.0
#     lat2 = 5.0
#     d_an, b_an = sail_route.haversine(lon1, lat1, lon2, lat2)
#     time_an = d/sail_route.perf_interp(polar, min_angle(wd_int, b), ws_int)
#     start = Dates.DateTime(2000, 1, 1, 0, 0, 0)
#     x_nodes = 5
#     y_nodes = 5
#     y_dist = 100.0
#     wisp, widi, cusp, cudi = sail_route.sample_weather()
#     st, ets = sail_route.route_solve(lon1, lon2, lat1, lat2, x_nodes, y_nodes, y_dist, wisp, widi, cusp, cudi, polar, start)
#     @test isapprox(st, time_an; rtol=0.0001)
# end