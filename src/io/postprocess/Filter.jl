export Filter, Blur, Sobel

struct Filter <: AbstractPostProcess
    op::Function
    filter::AT where AT <: Union{Array, CuArray, ROCArray}
    color::CT where CT <: Union{RGB, RGBA}
end

function Blur(; filter_size = 3, color = RGB(0,0,0))
end

function Sobel(; filter_size = 3, color = RGB(0,0,0))
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
