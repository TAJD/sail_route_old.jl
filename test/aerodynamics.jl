c_awa = sail_route.awa(60, 3.086, 5.144)
# @test isapprox(0.6669807044553968, c_awa, rtol=3)

@testset "Test apparent wind angle" begin
    @test isapprox(0.6669807044553968, c_awa, rtol=3)
end
