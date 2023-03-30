export run!

function solve(fums::Tuple{FractalUserMethod},
               y, x, red, green, blue, alpha, frame)

    if length(fums) == 0
        # do nothing
    elseif length(fums) == 1
        red, green, blue, alpha = fum.fx(y, x, red, green, blue, alpha;
                                         fum.kwargs...)
    else
        # recursive
        for i = 1:length(fums)
            solve(fums[i], y, x, red, green, blue, alpha)
        end

        # stack
#=
        s = Stack{Union{FractalUserMethod},Tuple}()
        push(s, fums)

        while length(s) > 0
            node = pop!(s)
            if isa(s, Tuple)
                for i = 1:length(fums)
                    push!(s, fums[i])
                end
            elseif isa(s, FractalUserMethod)
                red, green, blue, alpha = fum.fx(y, x, red, green, blue, alpha;
                                                 fum.kwargs...)
            end
        end
=#
    end
    return red, green, blue, alpha
end

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
                               layer.shader.fums,
                               frame,
                               ndrange = size(layer.canvas)))
end

@kernel function shader_kernel!(canvas, bounds, fums, frame)

    i, j = @index(Global, NTuple)
    res = @ndrange()

    @inbounds y = bounds.ymin + (i/res[1])*(bounds.ymax - bounds.ymin)
    @inbounds x = bounds.xmin + (j/res[2])*(bounds.xmax - bounds.xmin)

    red, green, blue, alpha = solve(fums, y, x, 0.0, 0.0, 0.0, 0.0, frame)

    canvas[i,j] = RGBA(red, green, blue, alpha)
end
