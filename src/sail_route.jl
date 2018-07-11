push!(LOAD_PATH,"./src/")

using Conda, PyCall

module sail_route

include("route/domain.jl")
include("weather/load_weather.jl")
include("scenarios/comparison.jl")
include("performance/aerodynamics.jl")
include("performance/polar.jl")

end
