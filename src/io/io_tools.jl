export write_image, write_video!, zero!, reset!

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

function reset!(a::Array{T}) where T <: Union{RGB, RGB{N0f8}}
    zero!(a)
end

function reset!(layer::FractalLayer; numthreads = 256, numcores = 4)
    zero!(layer)    
end

function reset!(layer::ColorLayer)
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

function to_rgb!(canvas, layer::FractalLayer)
    if !isa(layer.reds, Array)
        layer = to_cpu(layer)
    end
    canvas .= to_rgb.(layer.reds, layer.greens, layer.blues, layer.alphas)
end

function to_rgb!(canvas, bg::ColorLayer)
    canvas .= bg.color
end

function coalesce!(canvas::AL, in::AL) where AL <: AbstractLayer
    canvas.reds .= (1 .- in.alphas) .* canvas.reds .+ in.alphas .* in.reds
    canvas.greens .= (1 .- in.alphas) .* canvas.greens .+ in.alphas .* in.greens
    canvas.blues .= (1 .- in.alphas) .* canvas.blues .+ in.alphas .* in.blues
    canvas.alphas .= max.(canvas.alphas, in.alphas)
end

function logscale_coalesce!(canvas::AL, in::FractalLayer; numcores = 4,
                            numthreads = 256) where AL <: AbstractLayer
    if isa(layer.reds, Array)
        kernel! = logscale_coalesce_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = logscale_coalesce_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = logscale_coalesce_kernel!(ROCDevice(), numthreads)
    end

    kernel!(canvas.reds, canvas.greens, canvas.blues, canvas.alphas, canvas.values,
            in.reds, in.greens, in.blues, in.alphas, in.values,
            in.gamma, in.max_value, ndrange=length(layer.reds))

end

@kernel function logscale_coalesce_kernel!(
    canvas_reds, canvas_greens, canvas_blues, canvas_alphas,
    canvas_values, in_reds, in_greens,
    in_blues, in_alphas, in_values,
    in_gamma, in_max_value)

    tid = @index(Global, Linear)

    alpha = log10((9*in_values[tid]/in_max_value)+1)

    new_red = in_reds[tid]^(1/in_gamma) * alpha^(1/in_gamma)
    new_green = in_greens[tid]^(1/in_gamma) * alpha^(1/in_gamma)
    new_blue = in_blues[tid]^(1/in_gamma) * alpha^(1/in_gamma)
    new_alpha = in_alphas[tid]^(1/in_gamma) * alpha^(1/in_gamma)

    layer_reds[tid] = layer_reds[tid]*(1-alpha^(1/in_gamma)) + new_red
    layer_greens[tid] = layer_greens[tid]*(1-alpha^(1/in_gamma)) + new_green
    layer_blues[tid] = layer_blues[tid]*(1-alpha^(1/in_gamma)) + new_blue
    layer_alphas[tid] = layer_alphas[tid]*(1-alpha^(1/in_gamma)) + new_alpha
    
end

function norm_layer(color, value)
    if value == 0 || isnan(value)
        return color
    else
        return color / value
    end
end

function add_layer!(canvas::AL, layer::FractalLayer;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer

    # naive normalization
    layer.reds .= norm_layer.(layer.reds, layer.values)
    layer.greens .= norm_layer.(layer.greens, layer.values)
    layer.blues .= norm_layer.(layer.blues, layer.values)
    layer.alphas .= norm_layer.(layer.alphas, layer.values)

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

function add_layer!(canvas::AL, layer::AL;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer

    # naive normalization
    layer.reds .= norm_layer.(layer.reds, layer.values)
    layer.greens .= norm_layer.(layer.greens, layer.values)
    layer.blues .= norm_layer.(layer.blues, layer.values)
    layer.alphas .= norm_layer.(layer.alphas, layer.values)

    coalesce!(canvas, layer)
end

function write_image(layers::Vector{AL}, filename;
                     img = fill(RGB(0,0,0), size(layers[1].values)),
                     numcores = 4, numthreads = 256) where AL <: AbstractLayer

    for i = 1:length(layers)
        add_layer!(layers[1], layers[i])
    end

    to_rgb!(img, layers[1])

    save(filename, img)
    println(filename)
end

function write_video!(v::VideoParams, layers::Vector{AL};
                      numcores = 4, numthreads = 256) where AL <: AbstractLayer
    for i = 1:length(layers)
        add_layer!(layers[1], layers[i])
    end

    to_rgb!(v.frame, layers[1])
    write(v.writer, v.frame)
    zero!(v.frame)
    reset!(layers)
    println(v.frame_count)
    v.frame_count += 1
end
