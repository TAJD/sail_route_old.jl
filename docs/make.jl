push!(LOAD_PATH, "../src/")
include("../src/sail_route.jl")

using Documenter

makedocs(
    modules = [sail_route]
)
