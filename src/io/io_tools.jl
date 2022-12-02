export write_image, write_video!, zero!, reset!, create_canvas

function mix_layers!(layer_1::AL1, layer_2::AL2;
                     mode = :simple) where {AL1 <: AbstractLayer,
                                            AL2 <: AbstractLayer}

    if mode == :simple
        f = simple_layer_kernel!
    else
        error("Mixing mode ", string(mode), " not found!")
    end

    if layer_1.params.ArrayType <: Array
        kernel! = f(CPU(), layer_1.params.numcores)
    elseif has_cuda_gpu() && layer_1.params.ArrayType <: CuArray
        kernel! = f(CUDADevice(), layer_1.params.numthreads)
    elseif has_rocm_gpu() && layer_1.params.ArrayType <: ROCArray
        kernel! = f(ROCDevice(), layer_1.params.numthreads)
    end

    kernel!(layer_1.canvas, layer_2.canvas, ndrange = size(layer_1.canvas))

end

@kernel function simple_layer_kernel!(canvas_1, canvas_2)

    tid = @index(Global, Linear)

    @inbounds r = canvas_1[tid].r*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].r*canvas_2[tid].alpha
    @inbounds g = canvas_1[tid].g*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].g*canvas_2[tid].alpha
    @inbounds b = canvas_1[tid].b*(1-canvas_2[tid].alpha) +
                  canvas_2[tid].b*canvas_2[tid].alpha
    @inbounds a = max(canvas_1[tid].alpha, canvas_2[tid].alpha)

    @inbounds canvas_1[tid] = RGBA(r,g,b,a)
end

function create_canvas(s; ArrayType = Array)
    return ArrayType(fill(RGBA(0,0,0,0), s))
end

@kernel function zero_kernel!(layer_values, layer_reds, layer_greens, layer_blues)
    tid = @index(Global, Cartesian)
    layer_values[tid] = 0
    layer_reds[tid] = 0
    layer_greens[tid] = 0
    layer_blues[tid] = 0
end

function zero!(layer::AL) where AL <: AbstractLayer
    layer.canvas[:] .= RGBA(0.0, 0.0, 0.0, 0.0)
end

function zero!(a::Array{T}) where T <: Union{RGB, RGB{N0f8}}
    a[:] .= RGBA(0.0, 0.0, 0.0, 0.0)
end

function zero!(layer::FractalLayer)
    
    if layer.params.ArrayType <: Array
        kernel! = zero_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = zero_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = zero_kernel!(ROCDevice(), layer.params.numthreads)
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

function reset!(layer::AL) where AL <: AbstractLayer
    zero!(layer)
end

function write_image(layer;
                     filename::Union{Nothing, String} = nothing,
                     img = fill(RGBA(0,0,0),
                                size(layer.canvas))) where AL <: AbstractLayer

    postprocess!(layer)

    img .= Array(layer.canvas)

    reset!(layer)
    if isnothing(filename) || !OUTPUT
        return img
    else
        save(filename, img)
        println(filename)
    end
end


function write_image(layers::Vector{AL};
                     filename::Union{Nothing, String} = nothing,
                     img = fill(RGBA(0,0,0,0),
                                size(layers[1].canvas))) where AL<:AbstractLayer

    postprocess!(layers[1])
    for i = 2:length(layers)
        postprocess!(layers[i])
        wait(mix_layers!(layers[1], layers[i]; mode = :simple))
    end

    img .= Array(layers[1].canvas)

    reset!(layers)
    if isnothing(filename) || !OUTPUT
        return img
    else
        save(filename, img)
        println(filename)
    end
end

function write_video!(v::VideoParams,
                      layers::Vector{AL}) where AL <: AbstractLayer
 
    postprocess!(layers[1])
    for i = 2:length(layers)
        post_process!(layers[i])
        wait(mix_layers!(layers[1], layers[i]; mode = :simple))
    end

    v.frame .= Array(layers[1].canvas)

    if OUTPUT
        write(v.writer, v.frame)
    end
    zero!(v.frame)
    reset!(layers)
    println(v.frame_count)
    v.frame_count += 1
end

# in the case OUTPUT = false
function write_video!(n::Nothing, layers::Vector{AL}) where AL <: AbstractLayer
    postprocess!(layers[1])
    for i = 2:length(layers)
        post_process!(layers[i])
        wait(mix_layers!(layers[1], layers[i]; mode = :simple))
    end

    reset!(layers)
end
