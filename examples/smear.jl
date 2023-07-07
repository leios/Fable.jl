using Fable

function smear_example(num_particles, num_iterations, total_frames;
                       ArrayType = Array, output_type = :video)
    FloatType = Float32

    # define image domain
    world_size = (9, 16)
    ppu = 1920 / 16
    res = (1080, 1920)

    # defining video parameters
    if output_type == :video
        video_out = open_video(res; framerate = 30, filename = "out.mp4")
    end

    # define ball parameters
    object_position = fi("object_position", [-2.0, -2.0])
    ball = define_circle(; position = object_position,
                           radius = 1.0,
                           color = (1,1,1))

    # fractal inputs to track changes in position, scale, and theta for smear 
    scale = fi("scale", (1,1))
    theta = fi("theta", 0)

    # first defining the fractal user method
    smear = Smears.stretch_and_rotate(object_position = object_position,
                                      scale = scale, theta = theta)

    # now turning it into a fractal operator
    smear_transform = fee(Hutchinson, fo(smear))

    layer = FractalLayer(; ArrayType = ArrayType, FloatType = FloatType,
                         world_size = world_size, ppu = ppu,
                         num_particles = num_particles,
                         num_iterations = num_iterations,
                         H = ball, H_post = smear_transform)

    for i = 1:total_frames

        # changing ball position
        radius = 1.0
        pos = [-2.0+4*(i-1)/(total_frames-1),
               -2.0+4*(i-1)/(total_frames-1)]

        # creating a value that grows as it gets closer to total_frames / 2
        # and shrinks as it gets closer to total_frames
        scale_x = 2 - abs((i-1)*2-(total_frames-1))/(total_frames-1)

        # modifying fractal inputs for smear
        set!(object_position, pos)
        set!(scale, (1,scale_x))
        set!(theta, pi/4)

        run!(layer)

        if output_type == :video
            write_video!(video_out, [layer])
        elseif output_type == :image
            filename = "check"*lpad(i,5,"0")*".png"
            write_image([layer]; filename=filename)
        end

        # clearing frame
        zero!(layer)
    end

    if (output_type == :video)
        close_video(video_out)
    end

end

@info("Created Function: smear_example(num_particles, num_iterations,
                                      total_frames; ArrayType = Array,
                                      output_type = :video)\n"*
      "output_type can be {:video, :image}")
