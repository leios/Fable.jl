export write_image, write_video!, zero!, reset!, create_canvas

function mix_layers(layer_1::AL1, layer_2::AL2; mode = :simple, numcores = 4,
                    numthreads = 256) where {AL1 <: AbstractLayer,
                                             AL2 <: AbstractLayer}

    if mode == :simple
        f = simple_layer_kernel
    else
        error("Mixing mode ", string(mode), " not found!")
    end

    if isa(layer_1.reds, Array)
        kernel! = f(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer_1.reds, CuArray)
        kernel! = f(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer_1.reds, ROCArray)
        kernel! = f(ROCDevice(), numthreads)
    end

    kernel!(layer_1.canvas, layer_2.canvas, ndrange = size(layer_1.canvas))

end

@kernel function simple_layer_kernel!(canvas_1, canvas_2)

    tid = @index(Global, Linear)

    @inbounds r = canvas_1[tid].r*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].r*canvas_2.alpha
    @inbounds g = canvas_1[tid].g*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].g*canvas_2.alpha
    @inbounds b = canvas_1[tid].b*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].b*canvas_2.alpha
    @inbounds a = canvas_1[tid].alpah*canvas_2[tid].alpha

    @inbounds canvas_1[tid] = RGBA(r,g,b,a)
end

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

function reset!(layers::Vector{AL}; numthreads = 256,
                numcores = 4) where AL <: AbstractLayer
    for i = 1:length(layers)
        reset!(layers[i]; numthreads = numthreads, numcores = numcores)
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

function add_layer!(canvas::AL, layer::FractalLayer;
                    numcores = 4, numthreads = 256) where AL <: AbstractLayer

    postprocess!(layer)

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

    postprocess!(layer)

    coalesce!(canvas, layer)
end

function write_image(layer, filename;
                     img = fill(RGBA(0,0,0), size(layer.reds)),
                     numcores = 4, numthreads = 256) where AL <: AbstractLayer

    postprocess!(layer)

    img .= Array(layer.canvas)

    save(filename, img)
    println(filename)
end


function write_image(layers::Vector{AL}, filename;
                     img = fill(RGBA(0,0,0,0), size(layers[1].reds)),
                     numcores = 4, numthreads = 256) where AL <: AbstractLayer

    postprocess!(layers[1])
    for i = 2:length(layers)
        postprocess!(layers[i])
        mix_layers!(layers[1], layers[i]; mode = :simple,
                    numthreads = numthreads, numcores = numcores)
    end

    img .= Array(layers[1].canvas)

    save(filename, img)
    reset!(layers; numthreads = numthreads, numcores = numcores)
    println(filename)
end

function write_video!(v::VideoParams, layers::Vector{AL};
                      numcores = 4, numthreads = 256) where AL <: AbstractLayer
 
    postprocess!(layers[end])
    for i = 2:length(layers)
        post_process!(layers[i])
        mix_layers!(layers[1], layers[i])
    end

    v.frame .= Array(layers[1].canvas)

    write(v.writer, v.frame)
    zero!(v.frame)
    reset!(layers; numthreads = 256, numcores = numcores)
    println(v.frame_count)
    v.frame_count += 1
end
