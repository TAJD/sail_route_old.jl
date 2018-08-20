using PyCall

@pyimport importlib.machinery as machinery
loader = machinery.SourceFileLoader("failure",ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/failure_model/failure.py")
fail_models = loader[:load_module]("failure")

function load_env_failure_model()
    return fail_models[:gen_env_model]()
end

function interrogate_model(bp, tws, twa, h, theta)
    return fail_models[:env_bbn_interrogate](bp, tws, twa, h, theta)
end

# include poisson failure function here 
