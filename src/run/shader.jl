export run!

function run!(layer::ShaderLayer; diagnostic = false, frame = 0) 

    if layer.params.ArrayType <: Array
        kernel! = shader_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = shader_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = shader_kernel!(ROCDevice(), layer.params.numthreads)
    end

    bounds = find_bounds(layer)

    wait(@invokelatest kernel!(layer.canvas, bounds,
                               layer.shader.fxs,
                               combine(layer.shader.kwargs, layer.shader.fis),
                               frame,
                               ndrange = size(layer.canvas)))
end

@kernel function shader_kernel!(canvas, bounds, fxs, kwargs, frame)

    i, j = @index(Global, NTuple)
    res = @ndrange()

    @inbounds y = bounds.ymin + (i/res[1])*(bounds.ymax - bounds.ymin)
    @inbounds x = bounds.xmin + (j/res[2])*(bounds.xmax - bounds.xmin)

    for i = 1:length(fxs)
        red, green, blue, alpha = fxs[i](y, x, red, green, blue, alpha, frame;
                                         kwargs[i]...)
    end

    canvas[i,j] = RGBA(red, green, blue, alpha)
end
