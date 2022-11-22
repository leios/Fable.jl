# TODO: Deal with potential NaNs
function rgb_clip(a)
    if isnan(a)
        return 0
    else
        return min(abs(a), 1)
    end
end

function to_canvas!(layer::AL;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer
end

function to_canvas!(layer::FractalLayer; numcores = 4, numthreads = 256)
    if isa(layer.reds, Array)
        kernel! = FL_to_canvas_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = FL_to_canvas_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = FL_to_canvas_kernel!(ROCDevice(), numthreads)
    end

    wait(kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                 layer.alphas, layer.values, ndrange = length(layer.canvas)))
    
    return nothing
end

@kernel function FL_to_canvas_kernel!(canvas, layer_reds, layer_greens,
                                      layer_blues, layer_alphas, layer_values)
    tid = @index(Global, Linear)

    r = rgb_clip(layer_reds[tid]/layer_values[tid])
    g = rgb_clip(layer_greens[tid]/layer_values[tid])
    b = rgb_clip(layer_blues[tid]/layer_values[tid])
    a = rgb_clip(layer_alphas[tid]/layer_values[tid])

    @inbounds canvas[tid] = RGBA(r, g, b, a)

end

function postprocess!(layer::AL) where AL <: AbstractLayer
    to_canvas!(layer)   
end
