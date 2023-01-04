export Clip

struct Clip <: AbstractPostProcess
    op::Function
    clip_op::Function
    intensity_function::Function
    threshold::Number
    color::CT where CT <: Union{RGB, RGBA}
    initialized::Bool
end

function Clip(; threshold = 0.5, color = RGB(0,0,0),
                intensity_function = simple_intensity, clip_op = >)
    return Clip(clip!, clip_op, intensity_function, threshold, color, true)
end

function clip!(layer::AL, clip_params::Clip) where AL <: AbstractLayer

    if layer.params.ArrayType <: Array
        kernel! = clip_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = clip_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = clip_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.canvas, clip_params.clip_op,
                 clip_params.intensity_function,
                 clip_params.threshold, clip_params.color;
                 ndrange = size(layer.canvas)))
    
    return nothing

end

@kernel function clip_kernel!(canvas, clip_op, intensity_function, threshold, c)
    tid = @index(Global, Linear)
    if clip_op(intensity_function(canvas[tid]), threshold)
        canvas[tid] = c
    end
end
