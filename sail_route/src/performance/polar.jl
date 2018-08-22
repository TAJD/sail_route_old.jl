
using CSV, Interpolations, DataFrames
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/failure_model/failure.jl")


"""
    Performance(twa, tws, boat_perf)

Type to hold sailing craft performance information.

Arguments:

- twa: Array of true wind angles for each point in polar plot.
- tws: Array of true wind speeds for each point in polar plot.
- boat_perf: Dierckx 2D spline instance.

"""
struct Performance
    polar::Interpolations.GriddedInterpolation{}
    uncertainty::Float64
    acceptable_failure::Float64
    failure_model
end


"""
    load_file(path)

Load the file specified by path.
"""
function load_file(path)
    df = CSV.read(path, delim=';', datarow=1)
    perf = convert(Array{Float64}, df[2:end, 2:end])
    tws = convert(Array{Float64}, df[1, 2:end])
    twa = map(x->parse(Float64, x), df[2:end, 1])
    return twa, dropdims(tws, dims=1), perf
end


"""
    setup_interpolation(tws, twa, perf)

Return interpolation object.
"""
function setup_interpolation(tws, twa, perf)
    knots = (twa, tws)
    itp = interpolate(knots, perf, Gridded(Linear()))
    return itp
end


"""
    perf_interp(itp, twa, tws)

Return interpolated performance.
"""
function perf_interp(itp, twa, tws)
    return itp[twa, tws]
end


function h(cudi::AbstractFloat, cusp::AbstractFloat, bearing::AbstractFloat)
    cusp*sin(deg2rad(cudi-bearing))
end


function current(polar, cudi::AbstractFloat, cusp::AbstractFloat, widi::AbstractFloat,
    wisp::AbstractFloat, bearing::AbstractFloat, heading::AbstractFloat)
    vs = perf_interp(polar, min_angle(widi, heading), wisp)
    return (acos(h(cudi, cusp, bearing)/vs)*180/π - bearing)
end


"""
cost_function(performance, cudi::Float64, cusp::Float64,
                       widi::Float64, wisp::Float64,
                       wadi::Float64, wahi::Float64,
                       bearing::Float64)


Calculate the correct speed of the sailing craft given the failure model and environmental conditions.
"""
function cost_function(performance::Performance,
                       cudi::AbstractFloat, cusp::AbstractFloat,
                       widi::AbstractFloat, wisp::AbstractFloat,
                       wadi::AbstractFloat, wahi::AbstractFloat,
                       bearing::Float64)
    if performance.acceptable_failure == 1.0
        h1 = 0.0
        h2 = current(performance.polar, cudi, cusp, widi, wisp, bearing, h1)
        while h2 - h1 > 0.1
            h1 = h2
            h2 = current(performance.polar, cudi, cusp, widi, wisp, bearing, h1)
        end
        bearing = bearing + h2
        @inbounds vs = perf_interp(performance.polar, min_angle(widi, bearing), wisp)
        return vs + cusp
    else 
        pf = interrogate_model(performance.failure_model, wisp, widi, wahi, wadi)
        if pf < performance.acceptable_failure
            return Inf
        else
            h1 = 0.0
            h2 = current(performance.polar, cudi, cusp, widi, wisp, bearing, h1)
            while h2 - h1 > 0.1
                h1 = h2
                h2 = current(performance.polar, cudi, cusp, widi, wisp, bearing, h1)
            end
            bearing = bearing + h2
            @inbounds vs = perf_interp(performance.polar, min_angle(widi, bearing), wisp)
            return vs + cusp
        end
    end
end