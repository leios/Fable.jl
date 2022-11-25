export run!

function run!(layer::ColorLayer, bounds;
              name = "ColorLayer", diagnostic = false) 

    if isa(layer.reds, Array)
        kernel! = color_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = color_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = color_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.color, layer.canvas, ndrange = size(layer.convas)))
end

@kernel function color_kernel!(color, canvas)

    tid = @index(Global, Linear)

    @inbounds canvas[tid] = color
end
