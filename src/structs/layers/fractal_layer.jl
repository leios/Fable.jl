export FractalLayer, default_params, params

# Right now, points just holds positions... Probably can remove this abstraction
struct Points
    positions::Union{Array{}, CuArray{}, ROCArray{}} where T <: AbstractFloat
end

function Points(n::Int; ArrayType=Array, dims=2, FloatType=Float32,
                bounds=find_bounds((0,0), (2,2)))
    rnd_array = ArrayType(rand(FloatType,n,dims))
    for i = 1:dims
        rnd_array[:,i] .= rnd_array[:,i] .* (bounds[i*2] - bounds[i*2-1]) .+
                          bounds[i*2-1]
    end
    Points(rnd_array)
end

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
    position::Tuple
    world_size::Tuple
    ppu::Number
    params::NamedTuple
    postprocessing_steps::Vector{APP} where APP <: AbstractPostProcess
end

function default_params(a::Type{FractalLayer}; config = :standard,
                        ArrayType = Array, FloatType = Float32,
                        num_particles = 1000, num_iterations = 1000,
                        dims = 2)

    if config == :standard
        return (numthreads = 256, numcores = 4, gamma = 2.2, logscale = false,
                calc_max_value = false, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                solver_type = :semi_random, num_particles = num_particles,
                num_iterations = num_iterations)
    elseif config == :fractal_flame
        return (numthreads = 256, numcores = 4, gamma = 2.2, logscale = true,
                calc_max_value = true, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                solver_type = :semi_random, num_particles = num_particles,
                num_iterations = num_iterations)
    end
end

function params(a::Type{FractalLayer}; numthreads = 256, numcores = 4,
                ArrayType = Array, FloatType = Float32,
                logscale = false, gamma = 2.2, calc_max_value = false,
                max_value = 1, num_ignore = 20, num_particles = 1000,
                num_iterations = 1000, dims = 2, solver_type = :semi_random)
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
            dims = dims,
            solver_type = solver_type)
end


# Creating a default call
function FractalLayer(v, r, g, b, a, c, position, world_size, ppu;
                      postprocessing_steps = Vector{AbstractPostProcess}([]),
                      config = standard,
                      H1 = Hutchinson(), H2 = nothing)
    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    return FractalLayer(H1, H2, v, r, g, b, a, c, position, world_size, ppu,
                        default_params(FractalLayer,
                                       config = config,
                                       ArrayType = typeof(v),
                                       FloatType = eltype(v)),
                        postprocessing_steps)
end

# Create a blank, black image of size s
function FractalLayer(; config = :meh, ArrayType=Array, FloatType = Float32,
                      postprocessing_steps = Vector{AbstractPostProcess}([]),
                      world_size = (0.9, 1.6), position = (0.0, 0.0),
                      ppu = 1200, gamma = 2.2, logscale = false,
                      calc_max_value = false, max_value = 1,
                      numcores = 4, numthreads = 256,
                      num_particles = 1000, num_iterations = 1000, dims = 2,
                      H1 = Hutchinson(), H2 = nothing,
                      solver_type = :semi_random)
    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    res = (ceil(Int, world_size[1]*ppu), ceil(Int, world_size[2]*ppu))
    v = ArrayType(zeros(Int,res))
    r = ArrayType(zeros(FloatType,res))
    g = ArrayType(zeros(FloatType,res))
    b = ArrayType(zeros(FloatType,res))
    a = ArrayType(zeros(FloatType,res))
    c = ArrayType(fill(RGBA(FloatType(0),0,0,0), res))
    if config == :standard || config == :fractal_flame
        return FractalLayer(H1, H2, v, r, g, b, a, c, position, world_size, ppu,
                            default_params(FractalLayer;
                                           ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           config = config,
                                           num_particles = num_particles,
                                           num_iterations = num_iterations,
                                           dims = dims),
                            postprocessing_steps)
    else
        return FractalLayer(H1, H2, v, r, g, b, a, c, position, world_size, ppu,
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
                                   dims = dims,
                                   solver_type = solver_type),
                            postprocessing_steps)
    end
end

#------------------------------------------------------------------------------#
# CopyToCanvas for FractalLayer
#------------------------------------------------------------------------------#

struct CopyToCanvas <: AbstractPostProcess
    op::Function
    initialized::Bool
end

CopyToCanvas() = CopyToCanvas(to_canvas!, true)

function norm_layer!(layer::FractalLayer)
    layer.reds .= norm_component.(layer.reds, layer.values)
    layer.greens .= norm_component.(layer.greens, layer.values)
    layer.blues .= norm_component.(layer.blues, layer.values)
    layer.alphas .= norm_component.(layer.alphas, layer.values)
end

function norm_component(color, value)
    if value == 0 || isnan(value)
        return color
    else
        return color / value
    end
end

function to_canvas!(layer::FractalLayer, canvas_params::CopyToCanvas)
    to_canvas!(layer)
end

function to_canvas!(layer::FractalLayer)

    f = FL_canvas_kernel!
    if layer.params.logscale
        norm_layer!(layer)
        f = FL_logscale_kernel!
    end

    if layer.params.calc_max_value != 0
        update_params!(layer; max_value = maximum(layer.values))
    end

    if layer.params.ArrayType <: Array
        kernel! = f(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = f(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = f(ROCDevice(), layer.params.numthreads)
    end

    if layer.params.logscale
        wait(kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                     layer.alphas, layer.values, layer.params.gamma,
                     layer.params.max_value, ndrange = length(layer.canvas)))
    else
        wait(kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                     layer.alphas, layer.values,
                     ndrange = length(layer.canvas)))
    end
    
    return nothing
end

@kernel function FL_canvas_kernel!(canvas, layer_reds, layer_greens,
                                   layer_blues, layer_alphas, layer_values)
    tid = @index(Global, Linear)
    FT = eltype(layer_reds)

    val = layer_values[tid]

    # warp divergence, WOOOoooOOO
    if val > 0
        @inbounds r = min(layer_reds[tid]/val,1)
        @inbounds g = min(layer_greens[tid]/val,1)
        @inbounds b = min(layer_blues[tid]/val,1)
        @inbounds a = min(layer_alphas[tid]/val,1)

        @inbounds canvas[tid] = RGBA(r,g,b,a)
    else
        @inbounds canvas[tid] = RGBA(FT(0), 0, 0, 0)
    end

end

@kernel function FL_logscale_kernel!(canvas, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, layer_values,
                                     layer_gamma, layer_max_value)

    tid = @index(Global, Linear)
    FT = eltype(layer_reds)

    if layer_max_value != 0
        @inbounds alpha = log10((9*layer_values[tid]/layer_max_value)+1)
        @inbounds r = layer_reds[tid]^(1/layer_gamma)
        @inbounds g = layer_greens[tid]^(1/layer_gamma)
        @inbounds b = layer_blues[tid]^(1/layer_gamma)
        @inbounds a = layer_alphas[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds canvas[tid] = RGBA(r,g,b,a)
    else
        @inbounds canvas[tid] = RGBA(FT(0), 0, 0, 0)
    end
end
