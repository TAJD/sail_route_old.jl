push!(LOAD_PATH,"./src/")

using PyCall, Dates

module sail_route

include("performance/aerodynamics.jl")
include("weather/load_weather.jl")
include("performance/polar.jl")
include("route/discretization_error.jl")
include("route/domain.jl")
include("route/shortest_path.jl")



end
