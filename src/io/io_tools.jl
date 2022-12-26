export write_image, write_video!, zero!, reset!, create_canvas

function mix_layers!(layer_1::AL1, layer_2::AL2;
                     mode = :simple) where {AL1 <: AbstractLayer,
                                            AL2 <: AbstractLayer}

    overlap = find_overlap(layer_1, layer_2)
    mix_layers!(layer_1, layer_2, overlap)
end

function mix_layers!(layer_1::AL1, layer_2::AL2, overlap::Overlap;
                     mode = :simple) where {AL1 <: AbstractLayer,
                                            AL2 <: AbstractLayer}
    if layer_1.ppu !== layer_2.ppu
        error("Pixels per unit between layer 1 and 2 are not the same!")
    end

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

    kernel!(layer_1.canvas, layer_2.canvas,
            overlap.start_index_1, overlap.start_index_2,
            ndrange = overlap.range)

end

@kernel function simple_layer_kernel!(canvas_1, canvas_2,
                                      start_index_1, start_index_2)

    tid = @index(Global, Cartesian)
    idx_1 = CartesianIndex(Tuple(tid) .+ Tuple(start_index_1) .- (1,1))
    idx_2 = CartesianIndex(Tuple(tid) .+ Tuple(start_index_2) .- (1,1))

    @inbounds r = canvas_1[idx_1].r*(1-canvas_2[idx_2].alpha) +
                  canvas_2[idx_2].r*canvas_2[idx_2].alpha
    @inbounds g = canvas_1[idx_1].g*(1-canvas_2[idx_2].alpha) +
                  canvas_2[idx_2].g*canvas_2[idx_2].alpha
    @inbounds b = canvas_1[idx_1].b*(1-canvas_2[idx_2].alpha) +
                  canvas_2[idx_2].b*canvas_2[idx_2].alpha
    @inbounds a = max(canvas_1[idx_1].alpha, canvas_2[idx_2].alpha)

    @inbounds canvas_1[idx_1] = RGBA(r,g,b,a)
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

function reset!(layer::ColorLayer)
    layer.canvas .= layer.color
end

function write_image(layer;
                     filename::Union{Nothing, String} = nothing,
                     reset = true,
                     img = fill(RGBA(0,0,0),
                                size(layer.canvas))) where AL <: AbstractLayer

    postprocess!(layer)

    img .= Array(layer.canvas)

    if reset
        reset!(layer)
    end
    if isnothing(filename) || !OUTPUT
        return img
    else
        save(filename, img)
        println(filename)
    end
end


function write_image(layers::Vector{AL};
                     filename::Union{Nothing, String} = nothing,
                     reset = true,
                     img = fill(RGBA(0,0,0,0),
                                size(layers[1].canvas))) where AL<:AbstractLayer

    postprocess!(layers[1])
    for i = 2:length(layers)
        postprocess!(layers[i])
        wait(mix_layers!(layers[1], layers[i]; mode = :simple))
    end

    img .= Array(layers[1].canvas)

    if reset
        reset!(layers)
    end
    if isnothing(filename) || !OUTPUT
        return img
    else
        save(filename, img)
        println(filename)
    end
end

function write_video!(v::VideoParams,
                      layers::Vector{AL};
                      reset = true) where AL <: AbstractLayer
 
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
    if reset
        reset!(layers)
    end
    println(v.frame_count)
    v.frame_count += 1
end

# in the case OUTPUT = false
function write_video!(n::Nothing, layers::Vector{AL};
                      reset = true) where AL <: AbstractLayer
    postprocess!(layers[1])
    for i = 2:length(layers)
        post_process!(layers[i])
        wait(mix_layers!(layers[1], layers[i]; mode = :simple))
    end

    if reset
        reset!(layers)
    end
end
