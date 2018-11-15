
@testset "Test Kantorovich distance calculation" begin
    μ = [1/7, 2/7, 4/7]
    ν = [1/4, 1/4, 1/2]
    @test isapprox(0.107142857, sail_route.kantorovich_distance(μ, ν), rtol=4)

end
