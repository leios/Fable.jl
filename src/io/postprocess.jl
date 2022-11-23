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

function to_canvas!(layer::AL;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer
end

function to_canvas!(layer::FractalLayer; numcores = 4, numthreads = 256)

    if layer.logscale
        f = FL_canvas_kernel!
    else
        f = FL_logscale_kernel!
    end

    if layer.calc_max_value != 0
        layer.max_value = maximum(layer.values)
    end

    if isa(layer.reds, Array)
        kernel! = f(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = f(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = f(ROCDevice(), numthreads)
    end

    wait(kernel!(layer.canvas, layer.reds, layer.greens, layer.blues,
                 layer.alphas, layer.values, ndrange = length(layer.canvas)))
    
    return nothing
end

@kernel function FL_canvas_kernel!(canvas, layer_reds, layer_greens,
                                   layer_blues, layer_alphas, layer_values)
    tid = @index(Global, Linear)
    FT = eltype(layer_reds)

    # warp divergence, WOOOoooOOO
    if layer_values[tid] > 0
        @inbounds r = layer_reds[tid]/layer_values[tid]
        @inbounds g = layer_greens[tid]/layer_values[tid]
        @inbounds b = layer_blues[tid]/layer_values[tid]
        @inbounds a = layer_alphas[tid]/layer_values[tid]

        @inbounds canvas[tid] = RGBA(r,g,b,a)
    else
        @inbounds canvas[tid] = RGBA(FT(0), 0, 0, 0)
    end

end

@kernel function FL_logscale_kernel!(layer_reds, layer_greens, layer_blues,
                                     layer_alphas, layer_values, layer_gamma,
                                     layer_max_value)

    tid = @index(Global, Linear)
    FT = eltype(layer_reds)

    if layer_max_value == 0
        @inbounds alpha = log10((9*layer_values[tid]/layer_max_value)+1)
        @inbounds r = layer_reds[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds g = layer_greens[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds b = layer_blues[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds a = layer_alphas[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
        @inbounds canvas[tid] = RGBA(r,g,b,a)
    else
        @inbounds canvas[tid] = RGBA(FT(0), 0, 0, 0)
    end
end

function postprocess!(layer::AL) where AL <: AbstractLayer
    norm_layer!(layer)
    to_canvas!(layer)   
end

