using Dates

"""Convert hours in float to the nearest 4 hour interval."""
function convert_time(old_time::Float64)
    # h = floor(old_time)
    # m = floor((old_time - h)*60)
    mm = round(old_time*60/320)
    return Dates.Hour(mm*4)
    # return Dates.Hour(h)+Dates.Minute(m)
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
        ws_int = wisp[:sel](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx], number=0)
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
    y_dist = haversine(route.lon1, route.lon2, route.lat1, route.lat2)[1]/(route.y_nodes+1)
    x, y, land = co_ordinates(route.lon1, route.lon2, route.lat1, route.lat2,
                              route.x_nodes, route.y_nodes, y_dist)
    wisp = regrid_data(wisp, x[:, 1], y[:, 1])
    widi = regrid_data(widi, x[:, 1], y[:, 1])
    wadi = regrid_data(wadi, x[:, 1], y[:, 1])
    wahi = regrid_data(wahi, x[:, 1], y[:, 1])
    earliest_times = fill(Inf, size(x))
    prev_node = zero(x)
    node_indices = reshape(1:length(x), size(x)) 
    arrival_time = Inf
    for idx in 1:size(x)[2]
        if land[1, idx] == true
            earliest_times[1, idx] = Inf
        else
            @inbounds d, b = haversine(route.lon1, route.lat1, x[1, idx], y[1, idx])
            ws_int = wisp[:sel](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx], number=0, method="nearest")[:data][1]
            wd_int = widi[:sel](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx], number=0, method="nearest")[:data][1]
            wadi_int = wadi[:sel](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx], number=0, method="nearest")[:data][1]
            wahi_int = wahi[:sel](time=start_time, lon_b=x[1, idx], lat_b=y[1, idx], number=0, method="nearest")[:data][1]
            @inbounds speed = cost_function(performance, wd_int, ws_int, wadi_int, wahi_int, b)
            earliest_times[1, idx] = d/speed
        end
    end
    println(size(x)[1]-1)
    for idy in 1:size(x)[1]-1
        for idx1 in 1:size(x)[2]
            println(idy, " ", idx1, " ", land[idy, idx1], " ", earliest_times[idy, idx1])
            if land[idy, idx1] == true
                earliest_times[idy+1, idx1] = Inf
            else
                if isinf(earliest_times[idy, idx1]) == false
                    t = start_time + convert_time(earliest_times[idy, idx1])
                    ws_int = wisp[:sel](time=start_time, lon_b=x[idy+1, idx1], lat_b=y[idy+1, idx1], number=0, method="nearest")[:data][1]
                    wd_int = widi[:sel](time=start_time, lon_b=x[idy+1, idx1], lat_b=y[idy+1, idx1], number=0, method="nearest")[:data][1]
                    wadi_int = wadi[:sel](time=start_time, lon_b=x[idy+1, idx1], lat_b=y[idy+1, idx1], number=0, method="nearest")[:data][1]
                    wahi_int = wahi[:sel](time=start_time, lon_b=x[idy+1, idx1], lat_b=y[idy+1, idx1], number=0, method="nearest")[:data][1]
                    for idx2 in 1:size(x)[2]
                        @inbounds d, b = haversine(x[idy, idx1], y[idy, idx1], x[idy+1, idx2], y[idy+1, idx2])
                        @inbounds speed = cost_function(performance, wd_int, ws_int, wadi_int, wahi_int, b)
                        # println(idx2, " ", d, " ", b, " ", wd_int, " ", ws_int, " ", speed)
                        tt = earliest_times[idy, idx1] + d/speed
                        if earliest_times[idy+1, idx2] > tt
                            earliest_times[idy+1, idx2] = tt
                            prev_node[idy+1, idx2] = node_indices[idy, idx1]
                        end
                    end
                end
            end
        end
    end
    for idx in 1:size(x)[2]
        if isinf(earliest_times[end, idx]) == false
            @inbounds d, b = haversine(x[end, idx], y[end, idx], route.lon2, route.lat2)
            t = start_time + convert_time(earliest_times[end, idx])
            ws_int = wisp[:sel](time=t, lon_b=x[end, idx], lat_b=y[end, idx], number=0, method="nearest")[:data][1]
            wd_int = widi[:sel](time=t, lon_b=x[end, idx], lat_b=y[end, idx], number=0, method="nearest")[:data][1]
            wadi_int = wadi[:sel](time=t, lon_b=x[end, idx], lat_b=y[end, idx], number=0, method="nearest")[:data][1]
            wahi_int = wahi[:sel](time=t, lon_b=x[end, idx], lat_b=y[end, idx], number=0, method="nearest")[:data][1]
            @inbounds speed = cost_function(performance, wd_int, ws_int, wadi_int, wahi_int, b)
            # println(d, " ", b, " ", wd_int, " ", ws_int, " ", speed)
            tt = earliest_times[end, idx] + d/speed
            if arrival_time > tt
                arrival_time = tt
                final_node = node_indices[end, idx]
            end
        end
    end
    return arrival_time, earliest_times[end, :]
end
