push!(LOAD_PATH, "../src/")
include("../src/sail_route.jl")

using Documenter, sail_route
ENV["DOCUMENTER_DEBUG"]=true

makedocs(
    modules = [sail_route]
)


deploydocs(
    repo   = "github.com/TAJD/sail_route.jl.git",
    julia = "nightly",
    osname = "osx"
)
