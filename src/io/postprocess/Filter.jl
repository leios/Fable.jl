export Filter, Blur, Sobel

mutable struct Filter <: AbstractPostProcess
    op::Function
    filter::AT where AT <: Union{Array, CuArray, ROCArray}
    color::CT where CT <: Union{RGB, RGBA}
end

function gaussian(x,y, sigma)
    return (1/(2*pi*sigma*sigma)*exp(-((x*x + y*y)/(2*sigma*sigma)))
end

function Blur(; filter_size = 3, color = RGB(0,0,0), ArrayType = Array,
                sigma = 0.25)
    return Gaussian(; filter_size = filter_size, color = color,
                      ArrayType = ArrayType)
end

function Gaussian(; filter_size = 3, color = RGB(0,0,0), ArrayType = Array,
                    sigma = 0.25)
    filter = zeros(filter_size, filter_size)
    for i = 1:filter_size
        y = -1 + 2*(i-1)/(filter_size-1) 
        for j = 1:filter_size
            x = -1 + 2*(j-1)/(filter_size-1) 
            filter[i,j] = gaussian(x, y, sigma)
        end
    end
    return ArrayType(filter)
end

function Filter(filter; color = RGB(0,0,0))
    return Filter(filter!, filter, color)
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
        filter_params.filter = layer.params.ArrayType(filter)
    end

    wait(kernel!(layer.canvas, filter_params.filter,
                 filter_params.color; ndrange = size(layer.canvas)))
    
    return nothing

end

@kernel function filter_kernel!(canvas, filter, c)

    tid = @index(Global, Cartesian)

    overlap = find_overlap(tid, size(canvas), size(filter))

    for i = 1:overlap.range[1]
        for j = 1:overlap.range[2]
            val = canvas[overlap.start_index_1[1] + i - 1,
                         overlap.start_index_1[2] + j - 1] *
                  filter[overlap.start_index_2[1] + i - 1,
                         overlap.start_index_2[2] + j - 1]
        end
    end

    val = val / (overlap.range[1]*overlap.range[2])

    val = max(val, 1)

    canvas[tid] = c*val + canvas[tid]*(val-1)
end
