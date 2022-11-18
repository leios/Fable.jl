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
    tid = @index(Global, Linear)
    lid = @index(Local, Linear)
    res = @ndrange()

    shared_colors = @localmem eltype(layer_reds) (@groupsize()[1], 4)


    @inbounds y = bounds[1,2] + (i/res[1])*(bounds[1,2]-bounds[1,1])
    @inbounds x = bounds[2,2] + (j/res[2])*(bounds[2,2]-bounds[2,1])

    op(shared_colors, y, x, lid, symbols)

    @inbounds layer_reds[tid] = shared_colors[lid, 1]
    @inbounds layer_greens[tid] = shared_colors[lid, 2]
    @inbounds layer_blues[tid] = shared_colors[lid, 3]
    @inbounds layer_alphas[tid] = shared_colors[lid, 4]
end
