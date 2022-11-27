export run!

function run!(layer::ColorLayer, bounds; diagnostic = false) 

    if layer.params.ArrayType <: Array
        kernel! = color_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = color_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = color_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.color, layer.canvas, ndrange = size(layer.canvas)))
end

@kernel function color_kernel!(color, canvas)

    tid = @index(Global, Linear)

    @inbounds canvas[tid] = color
end
