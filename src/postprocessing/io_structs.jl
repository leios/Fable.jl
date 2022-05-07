export Pixels, open_video, close_video

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct Pixels
    values::Union{Array{I}, CuArray{I}} where I <: Integer
    reds::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    gamma::Number
    logscale::Bool
    calc_max_value::Bool
    max_value::Number
end

# Creating a default call
function Pixels(v, r, g, b; gamma = 2.2, logscale = true,
                calc_max_value = true, max_value = 0)
    return Pixels(v, r, g, b, gamma, logscale, calc_max_value, max_value)
end

# Create a blank, black image of size s
function Pixels(s; AT=Array, FT = Float64, gamma = 2.2, logscale = true,
                calc_max_value = true, max_value = 0)
    return Pixels(AT(zeros(Int,s)), AT(zeros(FT, s)),
                  AT(zeros(FT, s)), AT(zeros(FT, s)),
                  gamma, logscale, calc_max_value, max_value)
end

# frame is an intermediate frame before being written to the writer
mutable struct VideoParams
    writer::VideoIO.VideoWriter
    frame::Array{RGB{N0f8}}
    frame_count::Int
end

function VideoParams(res; framerate = 30, filename = "out.mp4",
                     encoder_options = (crf=23, preset="medium"))
    return VideoParams(VideoIO.VideoWriter(filename, RGB{N0f8}, res),
                       zeros(RGB{N0f8}, res), 0)
end

open_video(args...; kwargs...) = VideoParams(args...; kwargs...)

function close_video(v::VideoParams)
    close_video_out!(v.writer)
end
