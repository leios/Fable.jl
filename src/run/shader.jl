export run!

function run!(layer::ShaderLayer, res, bounds; numcores = 4, numthreads = 256,
              name = "ShaderLayer", diagnostic = false) 

    if !layer.configured
        fum = configure_fum(layer.fum, layer.fis; diagnostic = diagnostic,
                            fum_type = :color, name = name)
        layer.configured = true
    end


    if isa(layer.reds, Array)
        kernel! = naive_chaos_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = naive_chaos_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = naive_chaos_kernel!(ROCDevice(), numthreads)
    end

    kernel!(layer.symbols, layer.reds, layer.greens, layer.blues,
            layer.alphas, bounds, layer.op, ndrange = res)
end

# ideally, I don't need to use `res` and can just read find the NDRange
#     in the kernel...
@kernel function fum_kernel!(symbols, layer_reds, layer_greens, layer_blues,
                             layer_alphas, bounds, op)

    i, j = @index(Global, NTuple)
    res = @ndrange()

    @inbounds y = bounds[1,2] + (i/res[1])*(bounds[1,2]-bounds[1,1])
    @inbounds x = bounds[2,2] + (j/res[2])*(bounds[2,2]-bounds[2,1])

    layer_reds[i, j], layer_greens[i, j],
    layer_blues[i, j], layer_alphas[i, j] = op(x, y, symbols)
end
