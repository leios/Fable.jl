using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end


function main()

    squish = Fae.@fo function squish(x, factor)
        x *= factor
    end

    factor = Fae.fi("factor", 1.0)

    AT = CuArray
    FT = Float32

    frames = 10

    H = Fae.define_square([0.0,0.0], pi/8, 1.0, [1.0,0,1,1]; AT = AT)
    H_2 = Fae.Hutchinson([squish], [factor], [[1.0,1,1,0]], (1.0,);
                         AT = AT, FT = FT, final = true)

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    for i = 1:frames
        factor = Fae.fi("factor", 1-(i/frames))
        Fae.update_fis!(H_2, [factor])
        filename = "check"*lpad(i-1,5,"0")*".png"

        layers = Fae.fractal_flame(H, H_2, num_particles, num_iterations, bounds,
                                res; AT = AT, FT = FT)

        Fae.write_image([layers], filename)
    end

end

main()
