export Sobel

mutable struct Sobel <: AbstractPostProcess
    op::Function
    filter_x::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    filter_y::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    canvas_x::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    canvas_y::AT where AT <: Union{Array, CuArray, ROCArray, Nothing}
    initialized::Bool
end

Sobel() = Sobel(sobel!, nothing, nothing, nothing, nothing, false)

function initialize!(s::Sobel, layer::AL) where AL <: AbstractLayer
    ArrayType = layer.params.ArrayType
    canvas_size = size(layer.canvas)

    s.filter_x = ArrayType([1.0 0.0 -1.0;
                            2.0 0.0 -2.0;
                            1.0 0.0 -1.0])
    s.filter_y = ArrayType([ 1.0  2.0  1.0;
                             0.0  0.0  0.0;
                            -1.0 -2.0 -1.0])
    s.canvas_x = copy(layer.canvas)
    s.canvas_y = copy(layer.canvas)
    s.initialized = true
end

@kernel function quad_add!(output, canvas_y, canvas_x)
    tid = @index(Global, Linear)

    r = sqrt(canvas_y[tid].r*canvas_y[tid].r + canvas_x[tid].r*canvas_x[tid].r)
    g = sqrt(canvas_y[tid].g*canvas_y[tid].g + canvas_x[tid].g*canvas_x[tid].g)
    b = sqrt(canvas_y[tid].b*canvas_y[tid].b + canvas_x[tid].b*canvas_x[tid].b)
    if eltype(output) <: RGBA
        alpha = sqrt(canvas_y[tid].alpha*canvas_y[tid].alpha +
                     canvas_x[tid].alpha*canvas_x[tid].alpha)
        output[tid] = clip(RGBA(r, g, b, alpha), 1)
    else
        output[tid] = clip(RGB(r, g, b), 1)
    end
end

function sobel!(layer::AL, sobel_params::Sobel) where AL <: AbstractLayer
    sobel!(layer.canvas, layer, sobel_params)
end


function sobel!(output, layer::AL,
                sobel_params::Sobel) where AL <: AbstractLayer
    if layer.params.ArrayType <: Array
        kernel! = filter_kernel!(CPU(), layer.params.numcores)
        add_kernel! = quad_add!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = filter_kernel!(CUDADevice(), layer.params.numthreads)
        add_kernel! = quad_add!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = filter_kernel!(ROCDevice(), layer.params.numthreads)
        add_kernel! = quad_add!(ROCDevice(), layer.params.numthreads)
    end

    event_x = kernel!(sobel_params.canvas_x, output,
                      sobel_params.filter_x, ndrange = size(layer.canvas))
    event_y = kernel!(sobel_params.canvas_y, output,
                      sobel_params.filter_y, ndrange = size(layer.canvas))

    wait(event_x)
    wait(event_y)

    wait(add_kernel!(output, sobel_params.canvas_y,
                     sobel_params.canvas_x; ndrange = size(layer.canvas)))

    return nothing

end
