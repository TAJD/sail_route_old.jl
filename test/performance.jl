@testset "Test sailing craft performance functions" begin
    path = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    # path = ENV["HOME"]*"/.julia/v0.6/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = sail_route.load_file(path)
    @test twa[2] ≈ 60.0 atol=0.0
    @test tws[2] ≈ 8.0 atol=0.0
    @test perf[2, 2] ≈ 6.77 atol=0.0
    test_itp = sail_route.setup_perf_interpolation(tws, twa, perf)
    polar = sail_route.Performance(test_itp, 1.0, 1.0, nothing) 
    @test sail_route.perf_interp(polar, 60.0, 8.0/1.94384, 0.0, 0.0) ≈ 6.77 atol=0.0
end


@testset "Test cost function" begin
    

end