export Outline

mutable struct Outline <: AbstractPostProcess
    op::Function
    gauss_filter::FT where FT <: Union{Filter, Nothing}
    sobel::Sobel
    intensity_function::Function
    threshold::Number
    color::CT where CT <: Union{RGB, RGBA}
    canvas::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    initialized::Bool
end

function Outline(; linewidth = 1,
                   color = RGB(1.0, 1.0, 1.0),
                   intensity_function = simple_intensity,
                   clip_op = >,
                   threshold = 0.5,
                   sigma = 1,
                   ) where CT <: Union{RGB, RGBA}
    sobel = Sobel()
    if linewidth > 1
        gauss_filter = Blur(; filter_size = floor(Int, 3*linewidth),
                            sigma = sigma)
    else
        gauss_filter = nothing
    end
    return Outline(outline!, gauss_filter, sobel, intensity_function,
                   threshold, color, nothing, false)
end

function initialize!(o::Outline, layer::AL) where AL <: AbstractLayer
    if !isnothing(o.gauss_filter)
        initialize!(o.gauss_filter, layer)
    end
    initialize!(o.sobel, layer)
    o.canvas = copy(layer.canvas)
    o.initialized = true
end

function outline!(layer::AL, outline_params::Outline) where AL <: AbstractLayer

    if layer.params.ArrayType <: Array
        kernel! = ridge_kernel!(CPU(), layer.params.numcores)
        superimpose! = superimpose_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = ridge_kernel!(CUDADevice(), layer.params.numthreads)
        superimpose! = superimpose_kernel!(CUDADevice(),layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = ridge_kernel!(ROCDevice(), layer.params.numthreads)
        superimpose! = superimpose_kernel!(ROCDevice(), layer.params.numthreads)
    end

    if !isnothing(outline_params.gauss_filter)
        filter!(outline_params.canvas, layer, outline_params.gauss_filter)
    end
    sobel!(outline_params.canvas, layer, outline_params.sobel)

    wait(kernel!(outline_params.canvas, outline_params.intensity_function,
                 outline_params.threshold, outline_params.color;
                 ndrange = size(layer.canvas)))

    wait(superimpose!(layer.canvas, outline_params.canvas;
                      ndrange = size(layer.canvas)))
end

@kernel function ridge_kernel!(canvas, intensity_function, threshold, c)
    tid = @index(Global, Linear)
    if intensity_function(canvas[tid]) > threshold
        canvas[tid] = RGBA(c)
    else
        canvas[tid] = RGBA(0,0,0,0)
    end
end

@kernel function superimpose_kernel!(canvas, layer)
    tid = @index(Global, Linear)
    r = layer[tid].alpha*layer[tid].r + (1-layer[tid].alpha)*canvas[tid].r
    g = layer[tid].alpha*layer[tid].g + (1-layer[tid].alpha)*canvas[tid].g
    b = layer[tid].alpha*layer[tid].b + (1-layer[tid].alpha)*canvas[tid].b
    alpha = max(layer[tid].alpha, canvas[tid].alpha)
    canvas[tid] = RGBA(r, g, b, alpha)
end
