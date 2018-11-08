using CSV, Interpolations, DataFrames, Roots


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
    # etp0 = extrapolate(itp, 0.0)
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


"""Calculate the horizontal component of the current."""
function h(cudi, cusp, bearing)
    cusp*sind(cudi-bearing)
end


"""Calculate the resultant of the horizontal components of the boat and the current. The horizontal components of the speed of the vessel due to heading change and the current must be equal.

Bearing is the angle between waypoints. Heading is the actual course followed.

"""
function hor_result(performance, w_c_di, w_c_sp, wahi, wadi, cudi, cusp, bearing, heading)
    v = perf_interp(performance, min_angle(w_c_di, bearing), w_c_sp, wahi, wadi)
    return v*sind(bearing-heading) - cusp*sind(cudi-bearing)
end


# """Cost function not considering current."""
# function cost_function_no_current(performance::Performance,
#                        widi, wisp,
#                        wadi, wahi,
#                        bearing)
#     if widi > 360.0
#         return 0.0
#     elseif wisp > 20.0 # 20 m/s is a gale. Not good news.
#         return 0.0
#     elseif  min_angle(wadi, bearing) < 45.0
#         return 0.0
#     else
#         return perf_interp(performance, min_angle(widi, bearing), wisp, wahi, wadi)
#     end
# end


"""Check if the awa suggested is within the possible values for awa from the polar data."""
function check_brackets(bearing, twa)
    awa = min_angle(bearing, twa[1])
    heading_awa = awa
    max_awa = 160.0
    min_awa = 40.0
    max_awa_delta = max_awa - awa
    min_awa_delta = awa - min_awa
    delta = 0.0
    if min_awa_delta < 0 && max_awa_delta > 0
        bearing -= min_awa_delta 
    elseif min_awa_delta < 0 && max_awa_delta < 0
        bearing += max_awa_delta
    end
    return mod(bearing, 360.0)
end


"""
cost_function_canoe(performance, cudi::Float64, cusp::Float64,
                       widi::Float64, wisp::Float64,
                       wadi::Float64, wahi::Float64,
                       bearing::Float64)


Calculate the speed of the sailing craft given the failure model and environmental conditions. 
"""
function cost_function_canoe(performance::Performance,
                       cudi, cusp,
                       widi, wisp,
                       wadi, wahi,
                       bearing)
    w_c_di = mod(widi + cudi, 360.0)
    w_c_sp = wisp + cusp
    v = perf_interp(performance, min_angle(w_c_di, bearing), w_c_sp, wahi, wadi)
    resultant(x) = hor_result(performance, w_c_di, w_c_sp, wahi, wadi, cudi, cusp, bearing, x)
    low_bearing = check_brackets(bearing-45.0, w_c_di)
    high_bearing = check_brackets(bearing+45.0, w_c_di)
    try 
        phi = find_zero(resultant, (low_bearing, high_bearing), xatol=0.1)
        v = perf_interp(performance, min_angle(w_c_di, phi), w_c_sp, wahi, wadi)
        if min_angle(phi, bearing) > 60.0
            return 0.05
        end
        if v + cusp < 0.0
            return 0.05
        elseif min_angle(bearing, wadi) < 40.0
            return 0.5*(v+cusp)
        else
            return v + cusp
        end
    catch ArgumentError
        return 0.05
    end
end


"""
cost_function_conventional(performance, cudi::Float64, cusp::Float64,
                       widi::Float64, wisp::Float64,
                       wadi::Float64, wahi::Float64,
                       bearing::Float64)


Calculate the speed of the sailing craft given the failure model and environmental conditions. 
"""
function cost_function_conventional(performance::Performance,
                       cudi, cusp,
                       widi, wisp,
                       wadi, wahi,
                       bearing)
    w_c_di = mod(widi + cudi, 360.0)
    w_c_sp = wisp + cusp
    v = perf_interp(performance, min_angle(w_c_di, bearing), w_c_sp, wahi, wadi)
    resultant(x) = hor_result(performance, w_c_di, w_c_sp, wahi, wadi, cudi, cusp, bearing, x)
    low_bearing = check_brackets(bearing-45.0, w_c_di)
    high_bearing = check_brackets(bearing+45.0, w_c_di)
    try 
        phi = find_zero(resultant, (low_bearing, high_bearing), xatol=0.1)
        v = perf_interp(performance, min_angle(w_c_di, phi), w_c_sp, wahi, wadi)
        if min_angle(phi, bearing) > 60.0
            return 0.0
        end
        if v + cusp < 0.0
            return 0.0
        else
            return v + cusp
        end
    catch ArgumentError
        return 0.0
    end
end

cost_function(performance, cudi, cusp, widi, wisp, wadi, wahi, bearing) = cost_function_canoe(performance, cudi, cusp, widi, wisp, wadi, wahi, bearing)