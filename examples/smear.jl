using Fae, CUDA

function main(num_particles, num_iterations, total_frames, AT;
              output_type = :video)
    FT = Float32

    # define image domain
    res = (1080, 1920)
    bounds = [-4.5 4.5; -8 8]
    pix = Pixels(res; AT = AT, logscale = false, FT = FT)

    # defining video parameters
    if output_type == :video
        video_out = open_video(res; framerate = 30, filename = "out.mp4",
                               encoder_options = (crf=23, preset="medium"))
    end

    # define ball parameters
    radius = 1.0
    pos = [-2.0, -2.0]

    ball = define_circle(pos, radius, (1,1,1); AT = AT)

    # fractal inputs to track changes in position, scale, and theta for smear 
    object_position = fi("object_position", pos)
    scale = fi("scale", (1,1))
    theta = fi("theta", 0)

    fis = [object_position, scale, theta]
    
    # first defining the fractal user method
    smear = Smears.stretch_and_rotate(object_position = object_position,
                                      scale = scale, theta = theta)

    # now turning it into a fractal operator
    smear_transform = fee([FractalOperator(smear)], fis; name = "smear",
                          final = true, diagnostic = true)

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
        fractal_flame!(pix, ball, smear_transform, num_particles,
                       num_iterations, bounds, res;
                       AT = AT, FT = FT)

        if output_type == :video
            write_video!(video_out, [pix])
        elseif output_type == :image
            filename = "check"*lpad(i,5,"0")*".png"
            write_image([pix], filename)
        end

        # clearing frame
        zero!(pix)
    end

    if (output_type == :video)
        close_video(video_out)
    end

end
