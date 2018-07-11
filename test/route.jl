@testset "Test domain functions" begin
    dist, bearing = sail_route.haversine(-88.67, 36.12, -118.40, 33.94)
    @test dist ≈ 1462.22 atol = 0.01
    @test bearing ≈ 273.662 atol = 0.01

end
