export run!

function run!(layer::ShaderLayer, res, bounds; numcores = 4, numthreads = 256,
              name = "ShaderLayer", diagnostic = false) 

    if isa(layer.reds, Array)
        kernel! = shader_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(layer.reds, CuArray)
        kernel! = shader_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(layer.reds, ROCArray)
        kernel! = shader_kernel!(ROCDevice(), numthreads)
    end

    wait(kernel!(layer.shader.symbols, layer.reds, layer.greens, layer.blues,
                 layer.alphas, Tuple(bounds), layer.shader.op, ndrange = res))
end

@kernel function shader_kernel!(symbols, layer_reds, layer_greens, layer_blues,
                                layer_alphas, bounds, op)

    i, j = @index(Global, NTuple)
    tid = @index(Global, Linear)
    lid = @index(Local, Linear)
    res = @ndrange()

    shared_colors = @localmem eltype(layer_reds) (@groupsize()[1], 4)

    @inbounds y = bounds[1] + (i/res[1])*(bounds[3]-bounds[1])
    @inbounds x = bounds[2] + (j/res[2])*(bounds[4]-bounds[2])

    op(shared_colors, y, x, lid, symbols)

    @inbounds layer_reds[tid] = shared_colors[lid, 1]
    @inbounds layer_greens[tid] = shared_colors[lid, 2]
    @inbounds layer_blues[tid] = shared_colors[lid, 3]
    @inbounds layer_alphas[tid] = shared_colors[lid, 4]
end
