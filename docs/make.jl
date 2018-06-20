push!(LOAD_PATH, "../src/")
include("../src/sail_route.jl")

using Documenter

makedocs(
    modules = [sail_route]
)

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/TAJD/sail_route.jl.git",
    julia = "0.6",
    osname = "osx"
)
