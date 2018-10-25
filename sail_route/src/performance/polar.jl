using CSV, Interpolations, DataFrames


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
    setup_perf_interpolation(tws, twa, perf)

Return interpolation object.
"""
function setup_perf_interpolation(tws, twa, perf)
    knots = (twa, tws)
    itp = interpolate(knots, perf, Gridded(Linear()))
    etp0 = extrapolate(itp, Line())
    return etp0
end



"""Generic Aerrtsen typical speed loss values. Needs to be made more specific."""
function typical_aerrtsen()
    itp = interpolate(([0.2, 0.6, 1.5, 2.3, 4.2, 8.2],), [100.0, 99.0, 97.0, 94.0, 83.0, 60.0], Gridded(Linear()))
    etp = extrapolate(itp, Line())
    return etp
end

"""
    perf_interp(itp, twa, tws)

Return interpolated performance. Convert from ms to knots here.
"""
function perf_interp(performance, twa, tws, wahi, wadi)
    if performance.wave_resistance == nothing
        wave_res = 1.0
    else
        wave_res = performance.wave_resistance(wahi)/100.0
    end
    return performance.polar(twa, tws*1.94384)*performance.uncertainty*wave_res
end


function h(cudi, cusp, bearing)
    cusp*sind(cudi-bearing)
end


"""Calculate the current vector."""
function current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, heading)
    vs = perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
    height = h(cudi, cusp, bearing)/vs
    if abs(height/vs) < 1.0
        return (acosd(height/vs) - bearing)
    else
        return (acosd(1.0) - bearing)
    end
end


"""Cost function not considering current."""
function cost_function(performance::Performance,
                       widi, wisp,
                       wadi, wahi,
                       bearing)
    if widi > 360.0
        return 0.0
    elseif wisp > 20.0 # 20 m/s is a gale. Not good news.
        return 0.0
    elseif  wadi < 45.0
        return 0.0
    else
        return perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
    end
end


"""
cost_function(performance, cudi::Float64, cusp::Float64,
                       widi::Float64, wisp::Float64,
                       wadi::Float64, wahi::Float64,
                       bearing::Float64)


Calculate the correct speed of the sailing craft given the failure model and environmental conditions.
"""
function cost_function(performance::Performance,
                       cudi, cusp,
                       widi, wisp,
                       wadi, wahi,
                       bearing)
    h1 = 0.0
    h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
    while abs(h2 - h1) > 0.1
        h1 = h2
        h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
    end
    bearing = bearing + h2
    @inbounds vs = perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
    if vs+cusp < 0.0
        return 0.0
    else
        return vs + cusp
    end
end
# function cost_function(performance::Performance,
#                        cudi, cusp,
#                        widi, wisp,
#                        wadi, wahi,
#                        bearing)
#     if performance.acceptable_failure == 1.0
#         h1 = 0.0
#         h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
#         while h2 - h1 > 0.1
#             h1 = h2
#             h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
#         end
#         bearing = bearing + h2
#         @inbounds vs = perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
#         return vs + cusp
#     else 
#         pf = interrogate_model(performance.failure_model, wisp, widi, wahi, wadi)
#         if pf < performance.acceptable_failure
#             return Inf
#         else
#             h1 = 0.0
#             h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
#             while h2 - h1 > 0.1
#                 h1 = h2
#                 h2 = current(performance, cudi, cusp, widi, wisp, wahi, wadi, bearing, h1)
#             end
#             bearing = bearing + h2
#             @inbounds vs = perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
#             return vs + cusp
#         end
#     end
# end