export run!

@generated function shader_loop(fxs, y, x, color, frame, kwargs)
    exs = Expr[]
    for i = 1:length(fxs.parameters)
        ex = :(@inbounds color = fxs[$i](y, x, color, frame; kwargs[$i]...))
        push!(exs, ex)
    end

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end


function run!(layer::ShaderLayer; frame = 0) 

    backend = get_backend(layer.canvas)
    kernel! = shader_kernel!(backend, layer.params.numthreads)

    bounds = find_bounds(layer)

    kernel!(layer.canvas, bounds,
            layer.shader.fxs,
            combine(layer.shader.kwargs, layer.shader.fis),
            frame,
            ndrange = size(layer.canvas))
end

@kernel function shader_kernel!(canvas, bounds, fxs, kwargs, frame)

    i, j = @index(Global, NTuple)
    res = @ndrange()

    @inbounds y = bounds.ymin + (i/res[1])*(bounds.ymax - bounds.ymin)
    @inbounds x = bounds.xmin + (j/res[2])*(bounds.xmax - bounds.xmin)

    color = RGBA{Float32}(0,0,0,0)

    color = shader_loop(fxs, y, x, color, frame, kwargs)

    @inbounds canvas[i,j] = RGBA{Float32}(color)
end
