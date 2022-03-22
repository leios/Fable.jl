using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main()
    AT = CuArray
    FT = Float32

    num_particles = 10000
    num_iterations = 10000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    pos = [0.5, -1.5]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0.0
    radius = 0.75

    H = Fae.define_circle(pos, radius, color; AT = AT, diagnostic=true)

    pix = Fae.fractal_flame(H, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time Fae.write_image([pix], filename)
end

main()
