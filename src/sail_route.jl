push!(LOAD_PATH,"./src/")

using Conda, PyCall

module sail_route

include("scenarios/comparison.jl")
include("performance/aerodynamics.jl")
include("performance/polar.jl")

end
