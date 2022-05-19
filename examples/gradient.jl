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

    pos = [0.0, 0.0]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0.0
    scale_x = 0.5
    scale_y = 0.75

    color_1 = [1.0, 0, 0, 1]
    color_2 = [0, 1.0, 0, 1]
    color_3 = [0, 0, 1.0, 1]
    color_4 = [1.0, 0, 1.0, 1]

    colors = new_color_array([color_1, color_2, color_3, color_4], 4; AT = AT,
                             FT = FT)

    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, color; AT = AT)
    H.prob_set = (0.7, 0.1, 0.1, 0.1)
    H.color_set = colors

    pix = Fae.fractal_flame(H, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    println("image time:")
    @time Fae.write_image([pix], filename)
end

main()
