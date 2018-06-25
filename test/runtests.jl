# push!(LOAD_PATH,"./src/")
#
# include("/Users/thomasdickson/Documents/sail_route.jl/src/sail_route.jl")

using sail_route


using Base.Test
print("starting tests")
@time include("aerodynamics.jl")
