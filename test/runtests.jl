push!(LOAD_PATH,"./src/")

# include("/Users/thomasdickson/Documents/sail_route.jl/src/sail_route.jl")
# include("/home/thomas/sail_route.jl/src/sail_route.jl") # must be commented out

using sail_route


using Base.Test
print("starting tests")
@time include("aerodynamics.jl")
@time include("comparison.jl")
@time include("route.jl")
