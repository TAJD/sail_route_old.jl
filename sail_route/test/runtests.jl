push!(LOAD_PATH,"./src/")

using sail_route


using Base.Test
@time include("aerodynamics.jl")
@time include("route.jl")
@time include("comparison.jl")
@time include("route.jl")
@time include("performance.jl")
