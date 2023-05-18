export Clip

struct Clip <: AbstractPostProcess
    op::Function
    clip_op::Function
    intensity_function::Function
    threshold::Number
    color::CT where CT <: Union{RGB, RGBA}
    initialized::Bool
end

function Clip(op, clip_op, intensity_function, threshold, color)
    return Clip(op, clip_op, intensity_function, threshold, color, true)
end

function Clip(; threshold = 0.5, color = RGBA(0,0,0,1),
                intensity_function = simple_intensity, clip_op = >)
    return Clip(clip!, clip_op, intensity_function, threshold, color, true)
end

function clip!(layer::AL, clip_params::Clip) where AL <: AbstractLayer
    clip!(layer.canvas, layer, clip_params)
end

function clip!(output, layer::AL, clip_params::Clip) where AL <: AbstractLayer

    backend = get_backend(layer.canvas)
    kernel! = clip_kernel!(backend, layer.params.numthreads)

    kernel!(output, layer.canvas, clip_params.clip_op,
            clip_params.intensity_function,
            clip_params.threshold, clip_params.color;
            ndrange = size(layer.canvas))
    
    return nothing

end

@kernel function clip_kernel!(output, canvas, clip_op, intensity_function, threshold, c)
    tid = @index(Global, Linear)
    if clip_op(intensity_function(canvas[tid]), threshold)
        output[tid] = c
    end
end
