using Fable

function sierpinski_example(num_particles, num_iterations, num_frames;
                            ArrayType = Array, output_type = :video)

    if output_type == :video
        video_out = open_video((1080, 1920); framerate = 30,
                               filename = "out.mp4")
    end

    theta = 0
    r = 1
    A_1 = fi(:A_1, [r*cos(theta), r*sin(theta)])
    B_1 = fi(:B_1, [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)])
    C_1 = fi(:C_1, [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)])

    A_2 = fi(:A_2, [r*cos(-theta), r*sin(-theta)])
    B_2 = fi(:B_2, [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)])
    C_2 = fi(:C_2, [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)])

    H = create_triangle(; A = A_1, B = B_1, C = C_1,
                          color = [[1.0, 0.0, 0.0, 1.0],
                                   [0.0, 1.0, 0.0, 1.0],
                                   [0.0, 0.0, 1.0, 1.0]],
                          chosen_fx = :sierpinski)
    H_2 = create_triangle(A = A_2, B = B_2, C = C_2,
                            color = [[0.0, 1.0, 1.0, 1.0],
                                     [1.0, 0.0, 1.0, 1.0],
                                     [1.0, 1.0, 0.0, 1.0]],
                            chosen_fx = :sierpinski)

    final_H = fee(Hutchinson, [H, H_2])

    layer = FableLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = (2.25, 4), ppu = 1920/4,
                         num_iterations = num_iterations,
                         num_particles = num_particles, H = final_H)

    for i = 1:num_frames
        theta = 2*pi*(i-1)/num_frames
        set!(A_1, [r*cos(theta), r*sin(theta)])
        set!(B_1, [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)])
        set!(C_1, [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)])

        set!(A_2, [r*cos(-theta), r*sin(-theta)])
        set!(B_2, [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)])
        set!(C_2, [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)])

        run!(layer)

        if output_type == :video
            write_video!(video_out, [layer])
        elseif output_type == :image
            filename = "check"*lpad(i,5,"0")*".png"
            write_image([layer]; filename=filename)
        end

        zero!(layer)
    end

    if (output_type == :video)
        close_video(video_out)
    end

end

@info("Created Function: sierpinski_example(num_particles, num_iterations,
                                           num_frames; ArrayType = Array,
                                           output_type = :video)\n"*
      "output_type can be {:video, :image}")
