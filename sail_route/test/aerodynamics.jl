
@testset "Test apparent wind angle" begin
    @test isapprox(0.666980, sail_route.awa(60.0, 3.086, 5.144), rtol=3)
end
