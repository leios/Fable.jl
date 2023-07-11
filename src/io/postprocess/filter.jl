export Filter, Blur, Gaussian, Identity

mutable struct Filter <: AbstractPostProcess
    op::Function
    filter::AT where AT <: Union{AbstractArray, Nothing}
    canvas::AT where AT <: Union{AbstractArray, Nothing}
    initialized::Bool
end

function Filter(filter; ArrayType = Array)
    return Filter(filter!, ArrayType(filter), nothing, false)
end

function initialize!(filter::Filter, layer::AL) where AL <: AbstractLayer
    ArrayType = layer.params.ArrayType
    if !(typeof(filter.filter) <: layer.params.ArrayType)
        @info("filter array type not the same as canvas!\nConverting filter to canvas type...")
        filter.filter = ArrayType(filter.filter)
    end
    filter.canvas = ArrayType(zeros(eltype(layer.canvas), size(layer.canvas)))
end

function Identity(; filter_size = 3, ArrayType = Array)
    if iseven(filter_size)
        filter_size = filter_size - 1
        @warn("filter sizes must be odd! New filter size is " *
              string(filter_size)*"!")
    end
    filter = zeros(filter_size, filter_size)
    idx = ceil(Int, filter_size*0.5)
    filter[idx, idx] = 1

    return Filter(filter!, ArrayType(filter), nothing, false)
end

function gaussian(x,y, sigma)
    return (1/(2*pi*sigma*sigma))*exp(-((x*x + y*y)/(2*sigma*sigma)))
end

function Blur(; filter_size = 3, ArrayType = Array, sigma = 1.0)
    return Gaussian(; filter_size = filter_size, ArrayType = ArrayType,
                      sigma = sigma)
end

function Gaussian(; filter_size = 3, ArrayType = Array, sigma = 1.0)
    if iseven(filter_size)
        filter_size = filter_size - 1
        @warn("filter sizes must be odd! New filter size is " *
              string(filter_size)*"!")
    end
    if filter_size > 1
        filter = zeros(filter_size, filter_size)
        for i = 1:filter_size
            y = -1 + 2*(i-1)/(filter_size-1) 
            for j = 1:filter_size
                x = -1 + 2*(j-1)/(filter_size-1) 
                filter[i,j] = gaussian(x, y, sigma)
            end
        end
    else
        filter = [1.0]
    end

    filter ./= sum(filter)
    return Filter(filter!, ArrayType(filter), nothing, false)
end

function filter!(layer::AL, filter_params::Filter) where AL <: AbstractLayer
    filter!(layer.canvas, layer, filter_params)
end

function filter!(output, layer::AL,
                 filter_params::Filter) where AL <: AbstractLayer

    backend = get_backend(layer.canvas)
    kernel! = filter_kernel!(backend, layer.params.numthreads)

    kernel!(filter_params.canvas, layer.canvas, filter_params.filter;
            ndrange = size(layer.canvas))

    output .= filter_params.canvas
    
    return nothing

end

@kernel function filter_kernel!(canvas_out, canvas, filter)

    tid = @index(Global, Cartesian)

    (range, start_index_1, start_index_2) = find_overlap(tid,
                                                         size(canvas),
                                                         size(filter))

    red = 0.0
    green = 0.0
    blue = 0.0
    alpha = 0.0

    for i = 1:range[1]
        for j = 1:range[2]
            @inbounds red += canvas[start_index_1[1] + i - 1,
                                    start_index_1[2] + j - 1].r *
                             filter[start_index_2[1] + i - 1,
                                    start_index_2[2] + j - 1]
            @inbounds green += canvas[start_index_1[1] + i - 1,
                                     start_index_1[2] + j - 1].g *
                              filter[start_index_2[1] + i - 1,
                                     start_index_2[2] + j - 1]
            @inbounds blue += canvas[start_index_1[1] + i - 1,
                                     start_index_1[2] + j - 1].b *
                              filter[start_index_2[1] + i - 1,
                                     start_index_2[2] + j - 1]
            @inbounds alpha += canvas[start_index_1[1] + i - 1,
                                      start_index_1[2] + j - 1].alpha *
                               filter[start_index_2[1] + i - 1,
                                      start_index_2[2] + j - 1]
        end
    end

    @inbounds canvas_out[tid] = RGBA{Float32}(red, green, blue, alpha)
end
