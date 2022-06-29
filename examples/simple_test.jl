using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main()

    AT = Array
    FT = Float32

    H = Fae.define_square([0.0,0.0], 0.0, 1.0, [1,1,1,1]; AT = AT)
    #H = Fae.define_circle([0.0,0], 1.0, [1,1,1,1]; AT = AT)
    H2 = fee([Flames.perspective(theta = 0.25*pi, dist = 1)],
             [Fae.Colors.previous],
             (1,); name = "2", final = true)

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    filename = "check.png"

    #H_final = fee([H, H2])

    pix = Fae.fractal_flame(H, H2, num_particles, num_iterations, bounds,
                            res; AT = AT, FT = FT)

    println("Image generation time:")
    @time Fae.write_image([pix], filename)

end

main()
