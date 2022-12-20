export FractalLayer, default_params, params

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
    size::Tuple
    ppu::Int
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
function FractalLayer(v, r, g, b, a, c, position, size, ppu; config = standard,
                      H1 = Hutchinson(), H2 = Hutchinson())
    return FractalLayer(Hutchinson(), Hutchinson(),
                        v, r, g, b, a, c, position, size, ppu,
                        default_params(FractalLayer,
                                       config = config,
                                       ArrayType = typeof(v),
                                       FloatType = eltype(v)))
end

# Create a blank, black image of size s
function FractalLayer(; config = :meh, ArrayType=Array, FloatType = Float32,
                      size = (0.9, 1.6), position = (0.0, 0.0), ppu = 1200,
                      gamma = 2.2, logscale = false, calc_max_value = false,
                      max_value = 1, numcores = 4, numthreads = 256,
                      num_particles = 1000, num_iterations = 1000, dims = 2,
                      H1 = Hutchinson(), H2 = Hutchinson())
    res = (size[1]*ppu, size[2]*ppu)
    v = ArrayType(zeros(Int,res))
    r = ArrayType(zeros(FloatType,res))
    g = ArrayType(zeros(FloatType,res))
    b = ArrayType(zeros(FloatType,res))
    a = ArrayType(zeros(FloatType,res))
    c = ArrayType(fill(RGBA(FloatType(0),0,0,0), res))
    if config == :standard || config == :fractal_flame
        return FractalLayer(H1, H2, v, r, g, b, a, c, position, size, ppu,
                            default_params(FractalLayer;
                                           ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           config = config,
                                           num_particles = num_particles,
                                           num_iterations = num_iterations,
                                           dims = dims))
    else
        return FractalLayer(H1, H2, v, r, g, b, a, c, position, size, ppu,
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
