function norm_layer!(layer::AL) where AL <: AbstractLayer
end

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

function to_canvas!(layer::AL) where AL <: AbstractLayer
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

    if isa(layer.reds, Array)
        kernel! = f(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = f(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
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
        @inbounds r = layer_reds[tid]/val
        @inbounds g = layer_greens[tid]/val
        @inbounds b = layer_blues[tid]/val
        @inbounds a = layer_alphas[tid]/val

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

function postprocess!(layer::AL) where AL <: AbstractLayer
    to_canvas!(layer)   
end

