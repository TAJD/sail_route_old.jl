
using CSV, Interpolations, DataFrames

"""
    Performance(twa, tws, boat_perf)

Type to hold sailing craft performance information.

Arguments:

- twa: Array of true wind angles for each point in polar plot.
- tws: Array of true wind speeds for each point in polar plot.
- boat_perf: Dierckx 2D spline instance.

"""
mutable struct Performance
    twa
    tws
    boat_perf
    uncertainty::Float64
end


"""
    load_file(path)

Load the file specified by path.
"""
function load_file(path)
    df = CSV.read(path, delim=';', datarow=1)
    perf = Array{Float64}(df[2:end, 2:end])
    tws = Array{Float64}(df[1, 2:end])
    twa = map(x->parse(Float64, x), df[2:end, 1])
    return twa, squeeze(tws, 1), perf
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
