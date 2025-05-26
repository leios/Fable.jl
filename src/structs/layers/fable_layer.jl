export FableLayer, default_params, params, CopyToCanvas, to_canvas!

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct FableLayer <: AbstractLayer
    H::Union{Nothing, Hutchinson}
    H_post::Union{Nothing, Hutchinson}
    values::AIT where AIT <: AbstractArray{Int}
    reds::AFT where AFT <: AbstractArray{FT} where FT <: AbstractFloat
    greens::AFT where AFT <: AbstractArray{FT} where FT <: AbstractFloat
    blues::AFT where AFT <: AbstractArray{FT} where FT <: AbstractFloat
    alphas::AFT where AFT <: AbstractArray{FT} where FT <: AbstractFloat
    priorities::AFT where AFT <: Union{AbstractArray{UI},
                                       Nothing} where UI <: Unsigned
    canvas::ACT where ACT <: AbstractArray{CT} where CT <: RGBA
    generator::AbstractGenerator
    position::Tuple
    world_size::Tuple
    ppu::Number
    params::NamedTuple
    postprocessing_steps::Vector{APP} where APP <: AbstractPostProcess
end

function default_params(a::Type{FableLayer}; config = :standard,
                        ArrayType = Array, FloatType = Float32,
                        num_particles = 1000, num_iterations = 1000,
                        dims = 2)

    if config == :standard
        return (numthreads = 256, gamma = 2.2, logscale = false,
                calc_max_value = false, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                solver_type = :semi_random, num_particles = num_particles,
                num_iterations = num_iterations, overlay = false)
    elseif config == :fractal_flame
        return (numthreads = 256, gamma = 2.2, logscale = true,
                calc_max_value = true, max_value = 1, ArrayType = ArrayType,
                FloatType = FloatType, num_ignore = 20, dims = dims,
                solver_type = :semi_random, num_particles = num_particles,
                num_iterations = num_iterations, overlay = false)
    end
end

function params(a::Type{FableLayer}; numthreads = 256,
                ArrayType = Array, FloatType = Float32,
                logscale = false, gamma = 2.2, calc_max_value = logscale,
                max_value = 1, num_ignore = 20, num_particles = 1000,
                num_iterations = 1000, dims = 2, solver_type = :semi_random,
                overlay = false)
    return (numthreads = numthreads,
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
            solver_type = solver_type,
            overlay = overlay)
end


# Creating a default call
function FableLayer(v, r, g, b, a, pr, c, gen, position, world_size, ppu;
                    postprocessing_steps = AbstractPostProcess[],
                    config = standard,
                    H = Hutchinson(), H_post = nothing)
    if isa(H, FableOperator)
        H = Hutchinson(H)
    end

    if isa(H_post, FableOperator)
        H_post = Hutchinson(H_post)
    end

    if length(H) != size(p,2)
        error("Particles must be generated with `num_objects = "*
              string(length(H))*"`!")
    end

    if !isnothing(H_post) && length(H) != length(H_post)
        error("If post transformations are specified (H_post), each operator "*
              "must have a corresponding post transformation!")
    end

    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    return FableLayer(H, H_post, p, v, r, g, b, a, pr, c, gen,
                      position, world_size, ppu,
                      default_params(FableLayer,
                                     config = config,
                                     ArrayType = typeof(v),
                                     FloatType = eltype(v)),
                      postprocessing_steps)
end

# Create a blank, black image of size s
function FableLayer(; config = :meh, ArrayType=Array, FloatType = Float32,
                      postprocessing_steps = AbstractPostProcess[],
                      world_size = (0.9, 1.6), position = (0.0, 0.0),
                      ppu = 1200, gamma = 2.2, logscale = false,
                      calc_max_value = logscale, max_value = 1,
                      numthreads = 256,
                      num_particles = 1000, num_iterations = 1000, dims = 2,
                      H = Hutchinson(), H_post = nothing,
                      solver_type = :semi_random, overlay = false,
                      generator = RandGenerator())
    if isa(H, FableOperator)
        H = Hutchinson(H)
    end

    if isa(H_post, FableOperator)
        H_post = Hutchinson(H_post)
    end

    if !isnothing(H_post) && length(H) != length(H_post)
        error("If post transformations are specified (H_post), each operator "*
              "must have a corresponding post transformation!")
    end

    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    num_objects = length(H)

    res = (ceil(Int, world_size[1]*ppu), ceil(Int, world_size[2]*ppu))
    v = ArrayType(zeros(Int,res))
    r = ArrayType(zeros(FloatType,res))
    g = ArrayType(zeros(FloatType,res))
    b = ArrayType(zeros(FloatType,res))
    a = ArrayType(zeros(FloatType,res))
    if overlay
        pr = ArrayType(zeros(UInt64,res))
    else
        pr = nothing
    end
    c = ArrayType(fill(RGBA(FloatType(0),0,0,0), res))
    if config == :standard || config == :fractal_flame
        return FableLayer(H, H_post, v, r, g, b, a, pr, c, generator, 
                          position, world_size, ppu,
                          default_params(FableLayer;
                                         ArrayType = ArrayType,
                                         FloatType = FloatType,
                                         config = config,
                                         num_particles = num_particles,
                                         num_iterations = num_iterations,
                                         dims = dims),
                          postprocessing_steps)
    else
        return FableLayer(H, H_post, v, r, g, b, a, pr, c, generator, 
                          position, world_size, ppu,
                          params(FableLayer;
                                 ArrayType=ArrayType,
                                 FloatType = FloatType,
                                 gamma = gamma,
                                 logscale = logscale,
                                 calc_max_value = calc_max_value,
                                 max_value = max_value,
                                 numthreads = numthreads,
                                 num_particles = num_particles,
                                 num_iterations = num_iterations,
                                 dims = dims,
                                 solver_type = solver_type,
                                 overlay = overlay),
                          postprocessing_steps)
    end
end

#------------------------------------------------------------------------------#
# CopyToCanvas for FableLayer
#------------------------------------------------------------------------------#

struct CopyToCanvas <: AbstractPostProcess
    op::Function
    initialized::Bool
end

CopyToCanvas() = CopyToCanvas(to_canvas!, true)

function norm_layer!(layer::FableLayer)
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

function to_canvas!(layer::FableLayer, canvas_params::CopyToCanvas)
    to_canvas!(layer)
end

function to_canvas!(layer::FableLayer)

    f = FL_canvas_kernel!
    if layer.params.logscale
        norm_layer!(layer)
        f = FL_logscale_kernel!
    end

    if layer.params.calc_max_value
        update_params!(layer; max_value = maximum(layer.values))
    end

    backend = get_backend(layer.canvas)
    kernel! = f(backend, layer.params.numthreads)

    if layer.params.logscale
        kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                layer.alphas, layer.values, layer.params.gamma,
                layer.params.max_value, ndrange = length(layer.canvas))
    else
        kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                layer.alphas, layer.values,
                ndrange = length(layer.canvas))
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
        @inbounds canvas[tid] = RGBA(FT(0), FT(0), FT(0), FT(0))
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
        @inbounds canvas[tid] = RGBA(FT(0), FT(0), FT(0), FT(0))
    end
end
