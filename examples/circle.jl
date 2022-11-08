using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main()
    AT = Array
    #AT = CuArray
    FT = Float32

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    #pos = [-1, -1.5]
    pos = [0, 0.]
    #color = [0.5, 0.25, 0.75, 1]
    color = [1., 1, 1, 1]
    radius = 0.25
    #radius = 1.0

    new_loc = Fae.fi("loc",(0.5, 0.5))

    H = Fae.define_circle(pos, radius, color; AT = AT, diagnostic=true,
                          bounds = bounds, chosen_fx = :constant_disk)
    H2 = Fae.Hutchinson([Flames.shift(loc = new_loc),
                         Flames.waves(f = 0.5, c = 0.5, b = 2, e = 2)],
                        [new_loc],
                        [[1.0, 0, 1.0, 1.0],[0,1.0, 0, 1.0]], (0.75, 0.25);
                        final = true, diagnostic = true, AT = AT)

    layer = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time Fae.write_image([layer], filename)
end

main()
