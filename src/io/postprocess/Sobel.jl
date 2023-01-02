export Sobel

struct Sobel <: AbstractPostProcess
    op::Function
    filter_x::AT where AT <: Union{Array, CuArray, ROCArray}
    filter_y::AT where AT <: Union{Array, CuArray, ROCArray}
    canvas_x::AT where AT <: Union{Array, CuArray, ROCArray}
    canvas_y::AT where AT <: Union{Array, CuArray, ROCArray}
    color::CT where CT <: Union{RGB, RGBA}
    intensity_function::Function
end

function Sobel(; color = RGB(0,0,0), ArrayType = Array,
                 canvas_size = (1080, 1920),
                 intensity_function = simple_intensity)

    filter_x = ArrayType([1.0 0.0 -1.0;
                          2.0 0.0 -2.0;
                          1.0 0.0 -1.0])
    filter_y = ArrayType([ 1.0   2.0  1.0;
                           0.0   0.0  0.0;
                          -1.0 -2.0 -1.0])
    canvas_x = ArrayType(zeros(canvas_size))
    canvas_y = ArrayType(zeros(canvas_size))

    return Sobel(sobel!, filter_x, filter_y, canvas_x, canvas_y, color,
                 intensity_function)

end

function sobel!(layer::AL, sobel_params::Sobel) where AL <: AbstractLayer

    if layer.params.ArrayType <: Array
        kernel! = filter_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = filter_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = filter_kernel!(ROCDevice(), layer.params.numthreads)
    end

    sobel_params.canvas_x .= sobel_params.intensity_function.(layer.canvas)
    sobel_params.canvas_y .= sobel_params.intensity_function.(layer.canvas)

    wait(kernel!(sobel_params.canvas_x, sobel_params.filter_x,
                 sobel_params.intensity_function, 1.0;
                 ndrange = size(layer.canvas)))
    wait(kernel!(sobel_params.canvas_y, sobel_params.filter_y,
                 sobel_params.intensity_function, 1.0;
                 ndrange = size(layer.canvas)))

    intensity_function = sobel_params.intensity_function
    layer.canvas .= (sqrt.(sobel_params.canvas_x.^2 .*
                           sobel_params.canvas_y.^2)) .* sobel_params.color
    
    return nothing

end
