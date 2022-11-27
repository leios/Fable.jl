export run!

function run!(layer::ShaderLayer, bounds; diagnostic = false) 

    if layer.params.ArrayType <: Array
        kernel! = shader_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = shader_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = shader_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.shader.symbols, layer.canvas, Tuple(bounds),
                 layer.shader.op, ndrange = size(layer.canvas)))
end

@kernel function shader_kernel!(symbols, canvas, bounds, op)

    i, j = @index(Global, NTuple)
    tid = @index(Global, Linear)
    lid = @index(Local, Linear)
    res = @ndrange()

    shared_colors = @localmem eltype(canvas[1]) (@groupsize()[1], 4)

    @inbounds y = bounds[1] + (i/res[1])*(bounds[3]-bounds[1])
    @inbounds x = bounds[2] + (j/res[2])*(bounds[4]-bounds[2])

    op(shared_colors, y, x, lid, symbols)

    canvas[tid] = RGBA(shared_colors[lid, 1], shared_colors[lid, 2],
                       shared_colors[lid, 3], shared_colors[lid, 4])
end
