using Fae

function main(num_particles, num_iterations, total_frames, ArrayType;
              output_type = :video)
    FloatType = Float32

    # define image domain
    res = (1080, 1920)
    bounds = [-4.5 4.5; -8 8]
    layer = FractalLayer(res; ArrayType = ArrayType, FloatType = FloatType,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    # defining video parameters
    if output_type == :video
        video_out = open_video(res; framerate = 30, filename = "out.mp4")
    end

    # define ball parameters
    radius = 1.0
    pos = [-2.0, -2.0]

    ball = define_circle(pos, radius, (1,1,1))

    # fractal inputs to track changes in position, scale, and theta for smear 
    object_position = fi("object_position", pos)
    scale = fi("scale", (1,1))
    theta = fi("theta", 0)

    fis = [object_position, scale, theta]
    
    # first defining the fractal user method
    smear = Smears.stretch_and_rotate(object_position = object_position,
                                      scale = scale, theta = theta)

    # now turning it into a fractal operator
    smear_transform = fee(Hutchinson, [FractalOperator(smear)],
                          fis; name = "smear", final = true, diagnostic = true)

    layer.H1 = ball
    layer.H2 = smear_transform

    for i = 1:total_frames

        # changing ball position
        radius = 1.0
        pos = [-2.0+4*(i-1)/(total_frames-1),
               -2.0+4*(i-1)/(total_frames-1)]

        update_circle!(ball, pos, radius)

        # creating a value that grows as it gets closer to total_frames / 2
        # and shrinks as it gets closer to total_frames
        scale_x = 2 - abs((i-1)*2-(total_frames-1))/(total_frames-1)

        # modifying fractal inputs for smear
        object_position = set(object_position, pos)
        scale = set(scale, (1,scale_x))
        theta = set(theta, pi/4)

        update_fis!(smear_transform, [object_position, scale, theta])
        run!(layer, bounds)

        if output_type == :video
            write_video!(video_out, [layer])
        elseif output_type == :image
            filename = "check"*lpad(i,5,"0")*".png"
            write_image([layer], filename)
        end

        # clearing frame
        zero!(layer)
    end

    if (output_type == :video)
        close_video(video_out)
    end

end
