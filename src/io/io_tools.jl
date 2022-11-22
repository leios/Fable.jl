export write_image, write_video!, zero!, reset!, create_canvas

function create_canvas(s; AT = Array)
    return AT(fill(RGBA(0,0,0,0), s))
end

@kernel function zero_kernel!(layer_values, layer_reds, layer_greens, layer_blues)
    tid = @index(Global, Cartesian)
    layer_values[tid] = 0
    layer_reds[tid] = 0
    layer_greens[tid] = 0
    layer_blues[tid] = 0
end

function zero!(a::Array{T}) where T <: Union{RGB, RGB{N0f8}}
    a[:] .= RGB(0)
end

function zero!(layer; numthreads = 256, numcores = 4)
    
    if isa(layer.reds, Array)
        kernel! = zero_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = zero_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = zero_kernel!(ROCDevice(), numthreads)
    end

    kernel!(layer.values, layer.reds, layer.greens, layer.blues,
            ndrange = size(layer.values))

end

function reset!(layers::Vector{AL}) where AL <: AbstractLayer
    for i = 1:length(layers)
        reset!(layers[i])
    end
end

function reset!(a::Array{T};
                numthreads = 256, numcores = 4) where T <: Union{RGB, RGB{N0f8}}
    zero!(a; numthreads = numthreads, numcores = numcores)
end

function reset!(layer::AL;
                numthreads = 256, numcores = 4) where AL <: AbstractLayer
    zero!(layer; numthreads = numthreads, numcores = numcores)
end

function reset!(layer::ColorLayer; numthreads = 0, numcores = 0)
    layer.reds .= layer.color.r
    layer.blues .= layer.color.g
    layer.greens .= layer.color.b
    if isa(layer.color, RGBA)
        layer.alphas .= layer.color.a
    else
        layer.alphas .= 1
    end
end

function to_rgb(r,g,b)
    return RGB(r,g,b)
end

function to_rgb(r,g,b,a)
    return RGBA(r,g,b,a)
end

function to_rgb(layer::FractalLayer)
    if typeof(layer.reds) != Array
        layer = to_cpu(layer)
    end
    a = [RGBA(layer.reds[i], layer.greens[i], layer.blues[i], layer.alphas[i])
         for i = 1:length(layer)]
    return a
end

function to_cpu(layer::ShaderLayer)
    return ShaderLayer(layer.shader, Array(layer.reds), Array(layer.greens),
                       Array(layer.blues), Array(layer.alphas))
end

function to_cpu(layer::ColorLayer)
    return ColorLayer(layer.color, Array(layer.reds), Array(layer.greens),
                      Array(layer.blues), Array(layer.alphas))
end

function to_cpu(layer::FractalLayer)
    return FractalLayer(Array(layer.values), Array(layer.reds), Array(layer.greens),
                  Array(layer.blues), Array(layer.alphas), layer.gamma,
                  layer.logscale, layer.calc_max_value, layer.max_value)
end

function to_cpu!(cpu_layer, layer)
    cpu_layer.reds = Array(layer.reds)
    cpu_layer.greens = Array(layer.greens)
    cpu_layer.blues = Array(layer.blues)
    cpu_layer.alphas = Array(layer.alphas)
end

function to_rgb!(canvas, layer::AL) where AL <: AbstractLayer
    if !isa(layer.reds, Array)
        layer = to_cpu(layer)
    end
    canvas .= to_rgb.(layer.reds, layer.greens, layer.blues, layer.alphas)
end

function coalesce!(canvas::AL1, layer::AL2) where {AL1 <: AbstractLayer,
                                                   AL2 <: AbstractLayer}

    canvas.reds .= (1 .- layer.alphas) .* canvas.reds .+
                   layer.alphas .* layer.reds
    canvas.greens .= (1 .- layer.alphas) .* canvas.greens .+
                     layer.alphas .* layer.greens
    canvas.blues .= (1 .- layer.alphas) .* canvas.blues .+
                    layer.alphas .* layer.blues
    canvas.alphas .= max.(canvas.alphas, layer.alphas)
end

function logscale_coalesce!(canvas::AL, layer::FractalLayer; numcores = 4,
                            numthreads = 256) where AL <: AbstractLayer
    if isa(layer.reds, Array)
        kernel! = logscale_coalesce_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = logscale_coalesce_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = logscale_coalesce_kernel!(ROCDevice(), numthreads)
    end

    kernel!(canvas.reds, canvas.greens, canvas.blues, canvas.alphas, canvas.values,
            layer.reds, layer.greens, layer.blues, layer.alphas, layer.values,
            layer.gamma, layer.max_value, ndrange=length(layer.reds))

end

@kernel function logscale_coalesce_kernel!(
    canvas_reds, canvas_greens, canvas_blues, canvas_alphas,
    canvas_values, layer_reds, layer_greens,
    layer_blues, layer_alphas, layer_values,
    layer_gamma, layer_max_value)

    tid = @index(Global, Linear)

    alpha = log10((9*layer_values[tid]/layer_max_value)+1)

    new_red = layer_reds[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_green = layer_greens[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_blue = layer_blues[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_alpha = layer_alphas[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)

    layer_reds[tid] = layer_reds[tid]*(1-alpha^(1/layer_gamma)) + new_red
    layer_greens[tid] = layer_greens[tid]*(1-alpha^(1/layer_gamma)) + new_green
    layer_blues[tid] = layer_blues[tid]*(1-alpha^(1/layer_gamma)) + new_blue
    layer_alphas[tid] = layer_alphas[tid]*(1-alpha^(1/layer_gamma)) + new_alpha
    
end

function norm_layer!(layer::AL) where AL <: AbstractLayer
    return layer
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

function add_layer!(canvas::AL, layer::FractalLayer;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer

    # naive normalization
    norm_layer!(layer)

    if layer.logscale
        # This means the max_value is manually set
        if layer.calc_max_value != 0
            layer.max_value = maximum(layer.values)
        end
        logscale_coalesce!(layer, layer,
                           numcores = numcores, numthreads = numthreads)
    else
        coalesce!(canvas, layer)
    end
end

function add_layer!(canvas::AL1, layer::AL2;
                    numcores = 4, numthreads = 256) where {AL1 <: AbstractLayer,
                                                           AL2 <: AbstractLayer}

    # naive normalization
    norm_layer!(layer)

    coalesce!(canvas, layer)
end

function write_image(layer, filename;
                     img = fill(RGBA(0,0,0), size(layer.reds)),
                     numcores = 4, numthreads = 256) where AL <: AbstractLayer

    norm_layer!(layer)

    to_rgb!(img, layer)

    save(filename, img)
    println(filename)
end


function write_image(layers::Vector{AL}, filename;
                     img = fill(RGBA(0,0,0,0), size(layers[1].reds)),
                     numcores = 4, numthreads = 256) where AL <: AbstractLayer

    postprocess!(layers[1])
    for i = 2:length(layers)
        post_process!(layers[i])
        add_layer!(layers[1], layers[i])
    end

    to_rgb!(img, layers[1])

    save(filename, img)
    println(filename)
end

function write_video!(v::VideoParams, layers::Vector{AL};
                      numcores = 4, numthreads = 256) where AL <: AbstractLayer
 
    postprocess!(layers[1])
    for i = 2:length(layers)
        post_process!(layers[i])
        add_layer!(layers[1], layers[i])
    end

    to_rgb!(v.frame, layers[1])
    write(v.writer, v.frame)
    zero!(v.frame)
    reset!(layers[1]; numthreads = 256, numcores = numcores)
    println(v.frame_count)
    v.frame_count += 1
end
