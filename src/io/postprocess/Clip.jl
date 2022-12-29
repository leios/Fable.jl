export Clip

struct Clip <: AbstractPostProcess
    op::Function
    intensity_function::Function
    threshold::Number
    color::CT where CT <: Union{RGB, RGBA}
end

function Clip(; threshold = 0.5, color = RGB(0,0,0),
                intensity_function = simple_intensity)
    return Clip(clip!, intensity_function, threshold, color)
end

function clip!(layer::AL, clip_params::Clip) where AL <: AbstractLayer

    if isa(layer.canvas, Array)
        kernel! = clip_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && isa(layer.canvas, CuArray)
        kernel! = clip_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && isa(layer.canvas, ROCArray)
        kernel! = clip_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.canvas, clip_params.intensity_function,
                 clip_params.threshold, clip_params.color))
    
    return nothing

end

@kernel function clip_kernel!(canvas, intensity_function, threshold, c)
    tid = @index(Global, Linear)
    if intensity_function(canvas[tid]) > threshold
        canvas[tid] = c
    end
end
