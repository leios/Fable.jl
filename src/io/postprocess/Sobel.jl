export Sobel

struct Sobel <: AbstractPostProcess
    op::Function
    filter_x::AT where AT <: Union{Array, CuArray, ROCArray}
    filter_y::AT where AT <: Union{Array, CuArray, ROCArray}
    canvas_x::AT where AT <: Union{Array, CuArray, ROCArray}
    canvas_y::AT where AT <: Union{Array, CuArray, ROCArray}
    color::CT where CT <: Union{RGB, RGBA}
end

function Sobel(; color = RGB(0,0,0), ArrayType = Array,
                 canvas_size = (1080, 1920))

    filter_x = ArrayType([1.0 0.0 -1.0;
                          2.0 0.0 -2.0;
                          1.0 0.0 -1.0])
    filter_y = ArrayType([ 1.0   2.0  1.0;
                           0.0   0.0  0.0;
                          -1.0 -2.0 -1.0])
    canvas_x = ArrayType(zeros(canvas_size))
    canvas_y = ArrayType(zeros(canvas_size))

    return Sobel(sobel!, filter_x, filter_y, canvas_x, canvas_y, color)

end

function sobel!(layer::AL, filter_params::Filter) where AL <: AbstractLayer

    if isa(layer.canvas, Array)
        kernel! = filter_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && isa(layer.canvas, CuArray)
        kernel! = filter_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && isa(layer.canvas, ROCArray)
        kernel! = filter_kernel!(ROCDevice(), layer.params.numthreads)
    end

    filter_params.canvas_x .= layer.canvas
    filter_params.canvas_y .= layer.canvas

    wait(kernel!(filter_params.canvas_x, filter_params.filter_x,
                 filter_params.color; ndrange = size(layer.canvas)))
    wait(kernel!(filter_params.canvas_y, filter_params.filter_y,
                 filter_params.color; ndrange = size(layer.canvas)))

    layer.canvas .= sqrt.(filter_params.canvas_x.^2 .*
                          filter_params.canvas_y.^2)
    
    return nothing


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
