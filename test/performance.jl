@testset "Test sailing craft performance functions" begin
    path = ENV["HOME"]*"/sail_route.jl/src/data/first40_orgi.csv"
    twa, tws, perf = sail_route.load_file(path)
    @test twa[2] ≈ 60.0 atol=0.0
    @test tws[2] ≈ 8.0 atol=0.0
    @test perf[2, 2] ≈ 6.77 atol=0.0
    test_itp = sail_route.setup_interpolation(tws, twa, perf)
    @test sail_route.perf_interp(test_itp, 60.0, 8.0) ≈ 6.77 atol=0.0
end
