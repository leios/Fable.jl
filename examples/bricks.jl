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
    scene_1_frames = 5
    scene_2_frames = 5
    total_frames = scene_1_frames + scene_2_frames

    pos = [0.0, 0.0]
    color = [1., 1, 1, 1]
    rotation = 0.0
    scale_x = 1.0
    scale_y = 0.5

    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, color; AT = AT)

    brick_1_loc = Fae.fi("b_1_loc", (0, 2.1))
    brick_2_loc = Fae.fi("b_2_loc", (0, -2.1))
    brick_3_loc = Fae.fi("b_3_loc", (1.1, 1.05))
    brick_4_loc = Fae.fi("b_4_loc", (-1.1, -1.05))
    brick_5_loc = Fae.fi("b_5_loc", (1.1, -1.05))
    brick_6_loc = Fae.fi("b_6_loc", (-1.1, 1.05))

    H2 = Fae.Hutchinson([Fae.shift(loc = brick_1_loc),
                         Fae.shift(loc = brick_2_loc),
                         Fae.shift(loc = brick_3_loc),
                         Fae.shift(loc = brick_4_loc),
                         Fae.shift(loc = brick_5_loc),
                         Fae.shift(loc = brick_6_loc),
                         Fae.identity],
                        [brick_1_loc, brick_2_loc, brick_3_loc, brick_4_loc,
                         brick_5_loc, brick_6_loc],
                        [[1.0, 0, 0.0, 1],[0, 1.0, 0, 1], [0.0, 0.0, 1.0, 1.0],
                         [1,0,1.,1],[1,1,0,1],[0,1,1,1],[0,0,0,0]],
                        (1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7);
                        final = true, diagnostic = true, AT = AT)


    pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    #filename = "check"*lpad(i-1,5,"0")*".png"
    filename = "check.png"

    println("image time:")
    @time Fae.write_image([pix], filename)
end

main()
