push!(LOAD_PATH,"./src/")

using PyCall

module sail_route

include("performance/aerodynamics.jl")
include("performance/polar.jl")
include("route/domain.jl")
include("route/shortest_path.jl")
include("weather/load_weather.jl")


end
