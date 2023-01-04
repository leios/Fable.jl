export Filter, Blur, Gaussian, Identity

mutable struct Filter <: AbstractPostProcess
    op::Function
    filter::AT where AT <: Union{Array, CuArray, ROCArray}
    canvas::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    initialized::Bool
end

function initialize!(filter::Filter, layer::AL) where AL <: AbstractLayer
    filter.canvas = zeros(eltype(layer.canvas), size(layer.canvas))
end

function Identity(; filter_size = 3, ArrayType = Array)
    filter = zeros(filter_size, filter_size)
    idx = ceil(Int, filter_size*0.5)
    filter[idx, idx] = 1*filter_size*filter_size

    return Filter(filter!, ArrayType(filter), nothing, false)
end

function gaussian(x,y, sigma)
    return (1/(2*pi*sigma*sigma))*exp(-((x*x + y*y)/(2*sigma*sigma)))
end

function Blur(; filter_size = 3, ArrayType = Array, sigma = 0.25)
    return Gaussian(; filter_size = filter_size, ArrayType = ArrayType)
end

function Gaussian(; filter_size = 3, ArrayType = Array, sigma = 0.25)
    filter = zeros(filter_size, filter_size)
    for i = 1:filter_size
        y = -1 + 2*(i-1)/(filter_size-1) 
        for j = 1:filter_size
            x = -1 + 2*(j-1)/(filter_size-1) 
            filter[i,j] = gaussian(x, y, sigma)
        end
    end
    println(sum(filter))
    return Filter(filter!, ArrayType(filter), nothing, false)
end

function Filter(filter)
    return Filter(filter!, filter, nothing, false)
end

function filter!(layer::AL, filter_params::Filter) where AL <: AbstractLayer

    if isa(layer.canvas, Array)
        kernel! = filter_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && isa(layer.canvas, CuArray)
        kernel! = filter_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && isa(layer.canvas, ROCArray)
        kernel! = filter_kernel!(ROCDevice(), layer.params.numthreads)
    end

    if !(typeof(filter_params.filter) <: layer.params.ArrayType)
        @warn("filter array type not the same as canvas! Converting filter to canvas type...")
        filter_params = Filter(filter_params.op,
                               layer.params.ArrayType(filter_params.filter))
    end

    wait(kernel!(filter_params.canvas, layer.canvas, filter_params.filter;
                 ndrange = size(layer.canvas)))

    layer.canvas .= filter_params.canvas
    
    return nothing

end

@kernel function filter_kernel!(canvas_out, canvas, filter)

    tid = @index(Global, Cartesian)

    overlap = find_overlap(tid, size(canvas), size(filter))

    val = zero(eltype(canvas))

    for i = 1:overlap.range[1]
        for j = 1:overlap.range[2]
            val += canvas[overlap.start_index_1[1] + i - 1,
                          overlap.start_index_1[2] + j - 1] *
                   filter[overlap.start_index_2[1] + i - 1,
                          overlap.start_index_2[2] + j - 1]
        end
    end

    val = val / prod(size(filter))

    val = clip(val, 1)
    canvas_out[tid] = val
end
