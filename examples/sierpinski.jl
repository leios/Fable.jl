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
    frames = 300

    theta = 0
    r = 1
    A_1 = [r*cos(theta), r*sin(theta)]
    B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
    C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

    A_2 = [r*cos(-theta), r*sin(-theta)]
    B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
    C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

    H = Fae.define_sierpinski(A_1, B_1, C_1,
                              [1.0, 0.0, 0.0, 1.0],
                              [0.0, 1.0, 0.0, 1.0],
                              [0.0, 0.0, 1.0, 1.0]; AT = AT,
                              name = "s1")
    H_2 = Fae.define_sierpinski(A_2, B_2, C_2,
                                [0.0, 1.0, 1.0, 1.0],
                                [1.0, 0.0, 1.0, 1.0],
                                [1.0, 1.0, 0.0, 1.0]; AT = AT,
                                name = "s2")

    println("colors 1: ", H.color_set)
    println("colors 2: ", H_2.color_set)

    for i = 1:frames

        theta = 2*pi*(i-1)/frames
        A_1 = [r*cos(theta), r*sin(theta)]
        B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
        C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

        A_2 = [r*cos(-theta), r*sin(-theta)]
        B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
        C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

        Fae.update_sierpinski!(H, A_1, B_1, C_1; FT = FT, AT = AT)
        Fae.update_sierpinski!(H_2, A_2, B_2, C_2; FT = FT, AT = AT)

        pix = Fae.fractal_flame(H, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        @time Fae.write_image([pix], filename)
    end
end

main()
