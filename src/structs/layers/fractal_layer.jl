export FractalLayer, default_params, params

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct FractalLayer <: AbstractLayer
    H1::Union{Nothing, Hutchinson}
    H2::Union{Nothing, Hutchinson}
    particles::Union{Array{P}, CuArray{P}, ROCArray{P}} where P <: AbstractPoint
    values::Union{Array{I}, CuArray{I}, ROCArray{I}} where I <: Integer
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
function FractalLayer(p, v, c, position, world_size, ppu;
                      postprocessing_steps = AbstractPostProcess[],
                      config = standard,
                      H1 = Hutchinson(), H2 = nothing)
    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    return FractalLayer(H1, H2, p, v, c, position, world_size, ppu,
                        default_params(FractalLayer,
                                       config = config,
                                       ArrayType = typeof(v),
                                       FloatType = eltype(v)),
                        postprocessing_steps)
end

# Create a blank, black image of size s
function FractalLayer(; config = :meh, ArrayType=Array, FloatType = Float32,
                      postprocessing_steps = AbstractPostProcess[],
                      world_size = (0.9, 1.6), position = (0.0, 0.0),
                      ppu = 1200, gamma = 2.2, logscale = false,
                      calc_max_value = false, max_value = 1,
                      numcores = 4, numthreads = 256,
                      num_particles = 1000, num_iterations = 1000, dims = 2,
                      H1 = Hutchinson(), H2 = nothing,
                      solver_type = :semi_random)
    if logscale
        postprocessing_steps = vcat([FLLogscale()], postprocessing_steps)
    end

    res = (ceil(Int, world_size[1]*ppu), ceil(Int, world_size[2]*ppu))
    p = generate_points(num_particles; dims = dims, ArrayType = ArrayType)
    v = ArrayType(zeros(Int,res))
    c = ArrayType(fill(RGBA(FloatType(0),0,0,0), res))
    if config == :standard || config == :fractal_flame
        return FractalLayer(H1, H2, p, v, c, position, world_size, ppu,
                            default_params(FractalLayer;
                                           ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           config = config,
                                           num_particles = num_particles,
                                           num_iterations = num_iterations,
                                           dims = dims),
                            postprocessing_steps)
    else
        return FractalLayer(H1, H2, p, v, c, position, world_size, ppu,
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
# Logscale for FractalLayer
#------------------------------------------------------------------------------#

struct FLLogscale <: AbstractPostProcess
    op::Function
    initialized::Bool
end

FLLogscale() = FLLogscale(fractal_logscale!, true)

function to_canvas!(layer::FractalLayer)

    f = FL_logscale_kernel!

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

    wait(kernel!(layer.canvas, layer.values, layer.params.gamma,
                 layer.params.max_value, ndrange = length(layer.canvas)))

    return nothing
end

@kernel function FL_logscale_kernel!(canvas, layer_values,
                                     layer_gamma, layer_max_value)

    tid = @index(Global, Linear)

    if layer_max_value != 0
        @inbounds alpha = log10((9*layer_values[tid]/layer_max_value)+1)
        @inbounds a = layer_alphas[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds canvas[tid] = RGBA(canvas[tid].r,
                                     canvas[tid].g,
                                     canvas[tid].b,
                                     a)
    else
        @inbounds canvas[tid] = RGBA(FT(0), 0, 0, 0)
    end
end
