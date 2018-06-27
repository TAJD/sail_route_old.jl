push!(LOAD_PATH,"./src/")

using PyCall

module sail_route

include("scenarios/comparison.jl")
include("performance/aerodynamics.jl")

end
