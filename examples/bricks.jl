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

    pos = [-1.1, 1.05]
    color = [1., 1, 1, 1]
    rotation = 0.0
    scale_x = 1.0
    scale_y = 0.5

    fall_frames = 20
    curr_frame = 0

    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, color; AT = AT)

    for i = 1:fall_frames
        y_pos = 1.05 + 3.05*(i-fall_frames)/fall_frames
        pos = [-1.1, y_pos]
        Fae.update_rectangle!(H, pos, rotation, scale_x, scale_y, color;
                              FT = FT, AT = AT)
        filename = "check"*lpad(curr_frame,5,"0")*".png"
        curr_frame += 1
 
        pix = Fae.fractal_flame(H, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)
        @time Fae.write_image([pix], filename)
    end

    offset_array = zeros(6).+3.05

    for i = 1:6
        for j = 1:fall_frames
            offset_array[i] = 3.05*(j-fall_frames)/fall_frames
            brick_1_loc = Fae.fi("b_1_loc", (0+offset_array[1], 2.1))
            brick_2_loc = Fae.fi("b_2_loc", (-1.1+offset_array[2], -1.05))
            brick_3_loc = Fae.fi("b_3_loc", (-1.1+offset_array[3], 1.05))
            brick_4_loc = Fae.fi("b_4_loc", (-1.1+offset_array[4], 3.15))
            brick_5_loc = Fae.fi("b_5_loc", (-2.2+offset_array[5], 0))
            brick_6_loc = Fae.fi("b_6_loc", (-2.2+offset_array[6], 2.1))

            H2 = Fae.Hutchinson([Fae.shift(loc = brick_1_loc),
                                 Fae.shift(loc = brick_2_loc),
                                 Fae.shift(loc = brick_3_loc),
                                 Fae.shift(loc = brick_4_loc),
                                 Fae.shift(loc = brick_5_loc),
                                 Fae.shift(loc = brick_6_loc),
                                 Fae.identity],
                                [brick_1_loc,
                                 brick_2_loc,
                                 brick_3_loc,
                                 brick_4_loc,
                                 brick_5_loc,
                                 brick_6_loc],
                                [[1.0, 0, 0.0, 1],
                                 [0, 1.0, 0, 1],
                                 [0.0, 0.0, 1.0, 1.0],
                                 [1,0,1.,1],
                                 [1,1,0,1],
                                 [0,1,1,1],
                                 [0,0,0,0]],
                                (1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7);
                                final = true, diagnostic = true, AT = AT)


            pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                                    bounds, res; AT = AT, FT = FT)

            filename = "check"*lpad(curr_frame,5,"0")*".png"
            curr_frame += 1

            println("image time:")
            @time Fae.write_image([pix], filename)
        end
    end

    y_pos = 0
    for i = 1:fall_frames
        offset = 3.05*i/fall_frames
        y_pos = 1.05 + offset
        pos = [-1.1, y_pos]
        Fae.update_rectangle!(H, pos, rotation, scale_x, scale_y, color;
                              FT = FT, AT = AT)

        brick_1_loc = Fae.fi("b_1_loc", (0-offset, 2.1))
        brick_2_loc = Fae.fi("b_2_loc", (-1.1-offset, -1.05))
        brick_3_loc = Fae.fi("b_3_loc", (-1.1-offset, 1.05))
        brick_4_loc = Fae.fi("b_4_loc", (-1.1-offset, 3.15))
        brick_5_loc = Fae.fi("b_5_loc", (-2.2-offset, 0))
        brick_6_loc = Fae.fi("b_6_loc", (-2.2-offset, 2.1))

        H2 = Fae.Hutchinson([Fae.shift(loc = brick_1_loc),
                             Fae.shift(loc = brick_2_loc),
                             Fae.shift(loc = brick_3_loc),
                             Fae.shift(loc = brick_4_loc),
                             Fae.shift(loc = brick_5_loc),
                             Fae.shift(loc = brick_6_loc),
                             Fae.identity],
                            [brick_1_loc,
                             brick_2_loc,
                             brick_3_loc,
                             brick_4_loc,
                             brick_5_loc,
                             brick_6_loc],
                            [[1.0, 0, 0.0, 1],
                             [0, 1.0, 0, 1],
                             [0.0, 0.0, 1.0, 1.0],
                             [1,0,1.,1],
                             [1,1,0,1],
                             [0,1,1,1],
                             [0,0,0,0]],
                            (1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7);
                            final = true, diagnostic = true, AT = AT)


        pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(curr_frame,5,"0")*".png"
        curr_frame += 1
 
        @time Fae.write_image([pix], filename)
    end

    offset_array[:] .-= 3.05

    for i = 1:6
        for j = 1:fall_frames
            offset_array[i] = 3.05*(j-fall_frames)/fall_frames
            brick_1_loc = Fae.fi("b_1_loc", (0+offset_array[1], 2.1))
            brick_2_loc = Fae.fi("b_2_loc", (-1.1+offset_array[2], -1.05))
            brick_3_loc = Fae.fi("b_3_loc", (-1.1+offset_array[3], 1.05))
            brick_4_loc = Fae.fi("b_4_loc", (-1.1+offset_array[4], 3.15))
            brick_5_loc = Fae.fi("b_5_loc", (-2.2+offset_array[5], 0))
            brick_6_loc = Fae.fi("b_6_loc", (-2.2+offset_array[6], 2.1))

            H2 = Fae.Hutchinson([Fae.shift(loc = brick_1_loc),
                                 Fae.shift(loc = brick_2_loc),
                                 Fae.shift(loc = brick_3_loc),
                                 Fae.shift(loc = brick_4_loc),
                                 Fae.shift(loc = brick_5_loc),
                                 Fae.shift(loc = brick_6_loc),
                                 Fae.identity],
                                [brick_1_loc,
                                 brick_2_loc,
                                 brick_3_loc,
                                 brick_4_loc,
                                 brick_5_loc,
                                 brick_6_loc],
                                [[1.0, 0, 0.0, 1],
                                 [0, 1.0, 0, 1],
                                 [0.0, 0.0, 1.0, 1.0],
                                 [1,0,1.,1],
                                 [1,1,0,1],
                                 [0,1,1,1],
                                 [0,0,0,0]],
                                (1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7);
                                final = true, diagnostic = true, AT = AT)


            pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                                    bounds, res; AT = AT, FT = FT)

            filename = "check"*lpad(curr_frame,5,"0")*".png"
            curr_frame += 1

            println("image time:")
            @time Fae.write_image([pix], filename)
        end
    end

end

main()
