export run!

function run!(layer::ColorLayer, bounds; numcores = 4, numthreads = 256,
              name = "ColorLayer", diagnostic = false) 

    if isa(layer.reds, Array)
        kernel! = color_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = color_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = color_kernel!(ROCDevice(), numthreads)
    end

    wait(kernel!(layer.color, layer.canvas, ndrange = size(layer.convas)))
end

@kernel function color_kernel!(color, canvas)

    tid = @index(Global, Linear)

    @inbounds canvas[tid] = color
end
