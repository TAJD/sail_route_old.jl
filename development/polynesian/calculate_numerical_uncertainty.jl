include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")
using DataFrames, CSV, Revise, Dates, Statistics


function load_sample_data()
    file_10_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_10.0_nm.txt"
    file_15_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_20.0_nm.txt"
    file_20_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_40.0_nm.txt"

    file_10 = CSV.read(ENV["HOME"]*file_10_path, header=1, normalizenames=true)
    file_15 = CSV.read(ENV["HOME"]*file_15_path, header=1, normalizenames=true)
    file_20 = CSV.read(ENV["HOME"]*file_20_path, header=1, normalizenames=true)
    return file_10, file_15, file_20
end


function load_data(file_10_path, file_15_path, file_20_path)
    file_10 = CSV.read(ENV["HOME"]*file_10_path, header=1, normalizenames=true)
    file_15 = CSV.read(ENV["HOME"]*file_15_path, header=1, normalizenames=true)
    file_20 = CSV.read(ENV["HOME"]*file_20_path, header=1, normalizenames=true)
    return file_10, file_15, file_20
end


"""https://stackoverflow.com/questions/51432310/julia-convert-float64-to-date-and-to-datetime#51448499"""
function partial_year(period::Type{<:Period}, float::AbstractFloat)
    _year, Δ = divrem(float, 1)
    year_start = DateTime(_year)
    year = period((year_start + Year(1)) - year_start)
    partial = period(round(Dates.value(year) * Δ))
    year_start + partial
end


"""Return array of floats of finish times."""
function finish_dates(array)
    time_index, performance_index = size(array)
    converted_array = Array{Float64}(undef, time_index, performance_index)
    for i in 1:time_index
        for j in 2:performance_index
            hrs, rem = divrem(array[i, j], 1.0)
            mins = Dates.Minute(convert(Int64, round(rem*60)))
            hrs = Dates.Hour(convert(Int64, hrs))
            converted_array[i, j] = Dates.value(hrs) + Dates.value(mins)/60.0
        end
    end
    return converted_array
end


function GCI_calc_routing(small_results, medium_results, large_results,
                          h1, h2, h3)
    dates = small_results[1]
    small = finish_dates(small_results)
    medium = finish_dates(medium_results)
    large = finish_dates(large_results)
    gci_results = zeros(size(small))
    extrap_results =zeros(size(small))
    for i in eachindex(gci_results)
       gci_results[i] = GCI_calc(small[i], medium[i], large[i], 
                                 h1, h2, h3)
       extrap_results[i] = extrap_value(small[i], medium[i], large[i],
                                        h1, h2, h3)
    end
    df1 = DataFrame(gci_results[:, 2:end])
    df1.start_times = dates
    df2 = DataFrame(extrap_results[:, 2:end])
    df2.start_times = dates
    return df1, df2
end


function apply_GCI_index_test()
    f10, f15, f20 = load_data()
    results = GCI_calc_routing(f10, f15, f20, 10.0, 15.0, 20.0)
    small = finish_dates(f10)
    medium = finish_dates(f15)
    large = finish_dates(f20)
    ind = GCI_calc(small[1, 2], medium[1, 2], large[1, 2], 10.0, 15.0, 20.0)
    if isapprox(results[1, 1], ind) == false
        println("you've fucked gci calcs")
    end
end


function analyse_GCI_index(df)
    # create column calculating the average GCI
    df["Average GCI"] = mean.(df[1:20])
    @show mean(df["Average GCI"])
end


function save_GCI_initial_analysis(file_10_path, file_15_path,
                                   file_20_path, save_path)
    f10, f15, f20 = load_data(file_10_path, file_15_path, file_20_path)
    gci, extrap = GCI_calc_routing(f10, f15, f20, 10.0, 20.0, 40.0)
    CSV.write(save_path*"_GCI.txt", gci)
    CSV.write(save_path*"_extrap.txt", extrap)
end


function run_GCI_analysis()
    file_10_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_10.0_nm.txt"
    file_15_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_20.0_nm.txt"
    file_20_path = "/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_40.0_nm.txt"
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00"
    save_GCI_initial_analysis(file_10_path, file_15_path,
                              file_20_path, save_path)
end

run_GCI_analysis()