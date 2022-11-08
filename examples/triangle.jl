using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main(num_particles, num_iterations, num_frames, AT)
    FT = Float32

    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    layer = FractalLayer(res; AT = AT, logscale = false, FT = FT)

    theta = 0
    r = 1
    A = [r*cos(theta), r*sin(theta)]
    B = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
    C = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

    H = Fae.define_triangle(A, B, C,
                            [[1.0, 0.0, 0.0, 1.0],
                            [0.0, 1.0, 0.0, 1.0],
                            [0.0, 0.0, 1.0, 1.0],
                            [1.0, 0.0, 1.0, 1.0]]; AT = AT,
                            name = "s1", chosen_fx = :fill)

    for i = 1:num_frames

        theta = 2*pi*(i-1)/num_frames
        A = [r*cos(theta), r*sin(theta)]
        B = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
        C = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

        Fae.update_triangle!(H, A, B, C; FT = FT, AT = AT)

        Fae.fractal_flame!(layer, H, num_particles, num_iterations,
                           bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        @time Fae.write_image([layer], filename)

        zero!(layer)
    end
end
