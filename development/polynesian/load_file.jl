# using DelimitedFiles

# if isempty(ARGS) == false
#     if isfile(ENV["HOME"]*"/temp.txt") == true
#         @everywhere open(ENV["HOME"]*"/temp.txt") do file
#             @everywhere i = readdlm(file)
#         end
#         jb = parse(Int64, ARGS[1])
#         if i != jb
#             @everywhere open(ENV["HOME"]*"/temp.txt", "w") do file
#                 i = parse(Int64, ARGS[1])
#                 writedlm(file, i, ", ")
#             end
#         end
#     end
# end

# if isempty(ARGS) == true
#     @everywhere open(ENV["HOME"]*"/temp.txt") do file
#         @everywhere i = readdlm(file)
#     end
# else
#     @everywhere open(ENV["HOME"]*"/temp.txt", "w") do file
#         @everywhere i = parse(Int64, ARGS[1])
#         writedlm(file, i, ", ")
#     end
# end

@everywhere using ParallelDataTransfer

if isempty(ARGS) == false
    @show i = parse(Int64, ARGS[1])
    @passobj 1 workers() i
end

@show i