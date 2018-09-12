include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")

using Test

@testset "Check discretization error routines" begin
    ooc, f_exact_21, e21a, e21ext, gci_fine_21, gci_coarse_21, ratio = apply_routine()
    @test isapprox(ooc, 1.786170, atol=0.00001)
    @test isapprox(f_exact_21, 0.971300, atol=0.00001)
    @test isapprox(e21a, 0.002020, atol=0.00001)
    @test isapprox(e21ext, 0.000824, atol=0.00001)
    @test isapprox(gci_fine_21, 0.001031, atol=0.00001)
    @test isapprox(gci_coarse_21, 0.003555, atol=0.00001)
    @test isapprox(ratio, 0.997980, atol=0.000001)
end