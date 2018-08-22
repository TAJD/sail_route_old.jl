using Dates

"""Convert hours in float to hours and minutes."""
function convert_time(old_time::Float64)
    h = floor(old_time)
    m = floor((old_time - h)*60)
    return Dates.Hour(h)+Dates.Minute(m)
end

struct Route
    lon1::Float64
    lon2::Float64
    lat1::Float64
    lat2::Float64
    x_nodes::Int64
    y_nodes::Int64
end

"Shortest path considering all weather conditions but no land."
function route_solve(route::Route, performance, start_time::DateTime, 
                     wisp::PyObject, widi::PyObject,
                     cusp::PyObject, cudi::PyObject,
                     wadi::PyObject, wahi::PyObject)
    y_dist = haversine(route.lon1, route.lon2, route.lat1, route.lat2)[1]/(route.y_nodes+1)
    x, y, land = co_ordinates(route.lon1, route.lon2, route.lat1, route.lat2,
                              route.x_nodes, route.y_nodes, y_dist)
    earliest_times = fill(Inf, size(x))
    prev_node = zero(x)
    node_indices = reshape(1:length(x), size(x)) 
    arrival_time = Inf
    @simd for idx in 1:size(x)[2]
        @inbounds d, b = haversine(route.lon1, route.lat1, x[1, idx], y[1, idx])
        ws_int = wisp[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        wd_int = widi[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        cs_int = cusp[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        cd_int = cudi[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        wadi_int = wadi[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        wahi_int = wahi[:interp](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        speed = cost_function(performance, cd_int, cs_int, wd_int, ws_int,
                              wadi_int, wahi_int, b)
        if speed != Inf
            earliest_times[1, idx] = d/speed
        else
            earliest_times[1, idx] = Inf
        end
    end
    
    for idy in 1:size(x)[1]-1
        @simd for idx in 1:size(x)[2]
            t = start_time + convert_time(earliest_times[idy, idx])
            @inbounds d, b = haversine(x[idy, idx], y[idy, idx], x[idy+1, idx], y[idy+1, idx])
            ws_int = wisp[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            wd_int = widi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            cs_int = cusp[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            cd_int = cudi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            wadi_int = wadi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            wahi_int = wahi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            @inbounds speed = cost_function(performance, cd_int, cs_int,
                                            wd_int, ws_int, wadi_int, wahi_int, b)
            if speed != Inf
                tt = earliest_times[idy, idx] + d/speed
                if earliest_times[idy+1, idx] > tt
                    earliest_times[idy+1, idx] = tt
                    prev_node[idy+1, idx] = node_indices[idy, idx]
                end
            end
        end
    end
    
    for idx in 1:size(x)[2]
        @inbounds d, b = haversine(x[end, idx], y[end, idx], route.lon2, route.lat2)
        t = start_time + convert_time(earliest_times[end, idx])
         ws_int = wisp[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         wd_int = widi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         cs_int = cusp[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         cd_int = cudi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         wadi_int = wadi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         wahi_int = wahi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         @inbounds speed = cost_function(performance, cd_int, cs_int,
                                         wd_int, ws_int, wadi_int, wahi_int, b)
        if speed != Inf 
            tt = earliest_times[end, idx] + d/speed
            if arrival_time > tt
                arrival_time = tt
                final_node = node_indices[end, idx]
            end
        end
    end
    return arrival_time, earliest_times
end


"Shortest path with no current but considering land."
function route_solve(route::Route, performance, start_time::DateTime, 
                     wisp::PyObject, widi::PyObject,
                     wadi::PyObject, wahi::PyObject)
    println("Using 'linear' interpolation")
    y_dist = haversine(route.lon1, route.lon2, route.lat1, route.lat2)[1]/(route.y_nodes+1)
    x, y, land = co_ordinates(route.lon1, route.lon2, route.lat1, route.lat2,
                route.x_nodes, route.y_nodes, y_dist)
    earliest_times = fill(Inf, size(x))
    prev_node = zero(x)
    node_indices = reshape(1:length(x), size(x)) 
    arrival_time = Inf
    @simd for idx in 1:size(x)[2]
        @inbounds d, b = haversine(route.lon1, route.lat1, x[1, idx], y[1, idx])
        ws_int = wisp[:interp](time=start_time, longitude=x[1, idx], latitude=y[1, idx], number=1, method="linear")[:data][1]
        wd_int = widi[:interp](time=start_time, longitude=x[1, idx], latitude=y[1, idx],  number=1,method="linear")[:data][1]
        wadi_int = wadi[:interp](time=start_time, longitude=x[1, idx], latitude=y[1, idx], number=1, method="linear")[:data][1]
        wahi_int = wahi[:interp](time=start_time, longitude=x[1, idx], latitude=y[1, idx], number=1, method="linear")[:data][1]
        speed = cost_function(performance, 0.0, 0.0, wd_int, ws_int,
                              wadi_int, wahi_int, b)
        if speed != Inf
            earliest_times[1, idx] = d/speed
        else
            earliest_times[1, idx] = Inf
        end
    end

    for idy in 1:size(x)[1]-1
        @simd for idx in 1:size(x)[2]
            t = start_time + convert_time(earliest_times[idy, idx])
            @inbounds d, b = haversine(x[idy, idx], y[idy, idx], x[idy+1, idx], y[idy+1, idx])
            ws_int = wisp[:interp](time=t, longitude=x[idy, idx], latitude=y[idy, idx], number=1, method="linear")[:data][1]
            wd_int = widi[:interp](time=t, longitude=x[idy, idx], latitude=y[idy, idx], number=1, method="linear")[:data][1]
            wadi_int = wadi[:interp](time=t, longitude=x[idy, idx], latitude=y[idy, idx], number=1, method="linear")[:data][1]
            wahi_int = wahi[:interp](time=t, longitude=x[idy, idx], latitude=y[idy, idx], number=1, method="linear")[:data][1]
            @inbounds speed = cost_function(performance, 0.0, 0.0,
                                            wd_int, ws_int, wadi_int, wahi_int, b)
            if speed != Inf
                tt = earliest_times[idy, idx] + d/speed
                if earliest_times[idy+1, idx] > tt
                    earliest_times[idy+1, idx] = tt
                    prev_node[idy+1, idx] = node_indices[idy, idx]
                end
            end
        end
    end

    for idx in 1:size(x)[2]
        @inbounds d, b = haversine(x[end, idx], y[end, idx], route.lon2, route.lat2)
        t = start_time + convert_time(earliest_times[end, idx])
        ws_int = wisp[:interp](time=t, longitude=x[end, idx], latitude=y[end, idx], number=1, method="linear")[:data][1]
        wd_int = widi[:interp](time=t, longitude=x[end, idx], latitude=y[end, idx], number=1, method="linear")[:data][1]
        wadi_int = wadi[:interp](time=t, longitude=x[end, idx], latitude=y[end, idx], number=1, method="linear")[:data][1]
        wahi_int = wahi[:interp](time=t, longitude=x[end, idx], latitude=y[end, idx], number=1, method="linear")[:data][1]
        @inbounds speed = cost_function(performance, 0.0, 0.0,
                                        wd_int, ws_int, wadi_int, wahi_int, b)
        if speed != Inf 
            tt = earliest_times[end, idx] + d/speed
            if arrival_time > tt
                arrival_time = tt
                final_node = node_indices[end, idx]
            end
            end
        end
    return arrival_time, earliest_times
end
