export FractalLayer, ColorLayer, ShaderLayer, open_video, close_video

abstract type AbstractLayer end;

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct FractalLayer <: AbstractLayer
    values::Union{Array{I}, CuArray{I}, ROCArray{I}} where I <: Integer
    reds::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    alphas::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    gamma::Number
    logscale::Bool
    calc_max_value::Bool
    max_value::Number
end

mutable struct ColorLayer <: AbstractLayer
    color::Union{RGB, RGBA}
    reds::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    alphas::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
end

mutable struct ShaderLayer <: AbstractLayer
    shader::Shader
    reds::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    alphas::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
end

function ColorLayer(c::CT, s; AT = Array) where CT<:Union{RGB, RGBA}
    if isa(c, RGB)
        c = RGBA(c)
    end
    return ColorLayer(c, AT(fill(c.r, s)), AT(fill(c.g, s)),
                      AT(fill(c.b, s)), AT(fill(c.alpha, s)))
end

# Creating a default call
function FractalLayer(v, r, g, b, a; gamma = 2.2, logscale = true,
                      calc_max_value = true, max_value = 0)
    return FractalLayer(v, r, g, b, a, gamma, logscale,
                        calc_max_value, max_value)
end

# Create a blank, black image of size s
function FractalLayer(s; AT=Array, FT = Float64, gamma = 2.2, logscale = true,
                      calc_max_value = true, max_value = 0)
    return FractalLayer(AT(zeros(Int,s)), AT(zeros(FT, s)),
                        AT(zeros(FT, s)), AT(zeros(FT, s)), AT(zeros(FT, s)),
                        gamma, logscale, calc_max_value, max_value)
end

function ShaderLayer(shader::Shader, s; AT = Array, FT = Float32)
    return ShaderLayer(shader, AT(zeros(s)), AT(zeros(s)),
                       AT(zeros(s)), AT(zeros(s)))
end

function ShaderLayer(fum::FractalUserMethod, s; AT = Array, FT = Float32)
    return ShaderLayer(Shader(fum), AT(zeros(s)), AT(zeros(s)),
                       AT(zeros(s)), AT(zeros(s)))
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
