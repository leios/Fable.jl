using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end


function main()

    AT = Array
    FT = Float32

    H = Fae.define_square([0.0,0.0], pi/8, 1.0, [1.0,0,1,1]; AT = AT)

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    filename = "check.png"

    layer = Fae.fractal_flame(H, num_particles, num_iterations, bounds,
                            res; AT = AT, FT = FT)

    println("Image generation time:")
    @time Fae.write_image([layer], filename)

end

main()
