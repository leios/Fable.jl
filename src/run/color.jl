export run!

function run!(layer::ColorLayer; frame = 0) 

    backend = get_backend(layer.canvas)
    kernel! = color_kernel!(backend, layer.params.numthreads)

    kernel!(layer.color, layer.canvas, ndrange = size(layer.canvas))
end

@kernel function color_kernel!(color, canvas)

    tid = @index(Global, Linear)

    @inbounds canvas[tid] = color
end
