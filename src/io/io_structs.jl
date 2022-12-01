export FractalLayer, ColorLayer, ShaderLayer, open_video, close_video,
       default_params, params, update_params!

abstract type AbstractLayer end;

function default_params(a::Type{AL}) where AL <: AbstractLayer
    return (numthreads = 256, numcores = 4,
            ArrayType = Array, FloatType = Float32)
end

function params(a::Type{AL}; numthreads = 256, numcores = 4, ArrayType = Array,
                FloatType = Float32) where AL <: AbstractLayer
    return (numthreads = numthreads,
            numcores = numcores,
            ArrayType = ArrayType,
            FloatType = FloatType)
end

function update_params!(layer::AL; kwargs...) where AL <: AbstractLayer
    some_keys = [keys(layer.params)...]
    some_values = [values(layer.params)...]

    new_keys = [keys(kwargs)...]
    new_values = [values(kwargs)...]

    for i = 1:length(some_keys)
        for j = 1:length(new_keys)
            if some_keys[i] == new_keys[j]
                some_values[i] = new_values[j]
            end
        end
    end

    layer.params = NamedTuple{Tuple(some_keys)}(some_values)
end

#------------------------------------------------------------------------------#
# Fractal Layer
#------------------------------------------------------------------------------#

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct FractalLayer <: AbstractLayer
    H1::Union{Nothing, Hutchinson}
    H2::Union{Nothing, Hutchinson}
    values::Union{Array{I}, CuArray{I}, ROCArray{I}} where I <: Integer
    reds::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    alphas::Union{Array{T}, CuArray{T}, ROCArray{T}} where T <: AbstractFloat
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    params::NamedTuple
end

function default_params(a::Type{FractalLayer}; config = :standard,
                        ArrayType = Array, FloatType = Float32,
                        num_particles = 1000, num_iterations = 1000,
                        dims = 2)

    if config == :standard
        return (numthreads = 256, numcores = 4, gamma = 2.2, logscale = false,
                calc_max_value = false, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                num_particles = num_particles, 
                num_iterations = num_iterations)
    elseif config == :fractal_flame
        return (numthreads = 256, numcores = 4, gamma = 2.2, logscale = true,
                calc_max_value = true, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                num_particles = num_particles, 
                num_iterations = num_iterations)
    end
end

function params(a::Type{FractalLayer}; numthreads = 256, numcores = 4,
                ArrayType = Array, FloatType = Float32,
                logscale = false, gamma = 2.2, calc_max_value = false,
                max_value = 1, num_ignore = 20, num_particles = 1000,
                num_iterations = 1000, dims = 2)
    return (numthreads = numthreads,
            numcores = numcores,
            ArrayType = ArrayType,
            FloatType = FloatType,
            logscale = logscale,
            gamma = gamma,
            max_value = max_value,
            calc_max_value = calc_max_value,
            num_ignore = num_ignore,
            num_particles = num_particles,
            num_iterations = num_iterations,
            dims = dims)
end


# Creating a default call
function FractalLayer(v, r, g, b, a, c; config = standard,
                      H1 = Hutchinson(), H2 = Hutchinson())
    return FractalLayer(Hutchinson(), Hutchinson(),
                        v, r, g, b, a, c, default_params(FractalLayer,
                                                         config = config,
                                                         ArrayType = typeof(v),
                                                         FloatType = eltype(v)))
end

# Create a blank, black image of size s
function FractalLayer(s; config = :meh, ArrayType=Array, FloatType = Float32,
                      gamma = 2.2, logscale = false, calc_max_value = false,
                      max_value = 1, numcores = 4, numthreads = 256,
                      num_particles = 1000, num_iterations = 1000, dims = 2,
                      H1 = Hutchinson(), H2 = Hutchinson())
    v = ArrayType(zeros(Int,s))
    r = ArrayType(zeros(FloatType,s))
    g = ArrayType(zeros(FloatType,s))
    b = ArrayType(zeros(FloatType,s))
    a = ArrayType(zeros(FloatType,s))
    c = ArrayType(fill(RGBA(FloatType(0),0,0,0), s))
    if config == :standard || config == :fractal_flame
        return FractalLayer(H1, H2, v, r, g, b, a, c,
                            default_params(FractalLayer;
                                           ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           config = config,
                                           num_particles = num_particles,
                                           num_iterations = num_iterations,
                                           dims = dims))
    else
        return FractalLayer(H1, H2, v, r, g, b, a, c,
                            params(FractalLayer;
                                   ArrayType=ArrayType,
                                   FloatType = FloatType,
                                   gamma = gamma,
                                   logscale = logscale,
                                   calc_max_value = calc_max_value,
                                   max_value = max_value,
                                   numcores = numcores,
                                   numthreads = numthreads,
                                   num_particles = num_particles,
                                   num_iterations = num_iterations,
                                   dims = dims))
    end
end

#------------------------------------------------------------------------------#
# Color Layer
#------------------------------------------------------------------------------#

mutable struct ColorLayer <: AbstractLayer
    color::Union{RGB, RGBA}
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    params::NamedTuple
end

function ColorLayer(c::CT, s; ArrayType = Array, FloatType = Float32,
                    numcores = 4, numthreads = 256) where CT<:Union{RGB, RGBA}
    if isa(c, RGB)
        c = RGBA(c)
    end

    c = RGBA{FloatType}(c)
    return ColorLayer(c, ArrayType(fill(c, s)), params(ColorLayer;
                                                ArrayType = ArrayType,
                                                FloatType = FloatType,
                                                numcores = numcores,
                                                numthreads = numthreads))
end

#------------------------------------------------------------------------------#
# Shader Layer
#------------------------------------------------------------------------------#

mutable struct ShaderLayer <: AbstractLayer
    shader::Shader
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    params::NamedTuple
end

function ShaderLayer(shader::Shader, s; ArrayType = Array, FloatType = Float32,
                     numcores = 4, numthreads = 256)
    return ShaderLayer(shader,
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), s)),
                       params(ShaderLayer; ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           numcores = numcores,
                                           numthreads = numthreads))
end

function ShaderLayer(fum::FractalUserMethod, s; ArrayType = Array,
                     FloatType = Float32, numcores = 4, numthreads = 256)
    return ShaderLayer(Shader(fum),
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), s)),
                       params(ShaderLayer; ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           numcores = numcores,
                                           numthreads = numthreads))
end

#------------------------------------------------------------------------------#
# Video Parameters
#------------------------------------------------------------------------------#

# frame is an intermediate frame before being written to the writer
mutable struct VideoParams
    writer::VideoIO.VideoWriter
    frame::Array{RGB{N0f8}}
    frame_count::Int
end

function VideoParams(res; framerate = 30, filename = "out.mp4",
                     encoder_options = (crf=23,
                                        preset="medium",
                                        pixel_format = "yuv420p"))
    return VideoParams(VideoIO.VideoWriter(filename, RGB{N0f8}, res;
                                           framerate = framerate,
                                           encoder_options = encoder_options),
                       zeros(RGB{N0f8}, res), 0)
end

function open_video(args...; kwargs...)
    if OUTPUT
        return VideoParams(args...; kwargs...)
    else
        return nothing
    end
end

function close_video(v::VideoParams)
    close_video_out!(v.writer)
end

# In the case OUTPUT = false
function close_video(n::Nothing)
end
