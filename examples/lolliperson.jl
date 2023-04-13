using Fable, Images

function lolli_example(num_particles, num_iterations;
                       height = 2.0, brow_height = 0.5,
                       ArrayType = Array, num_frames = 10,
                       transform_type = :check, filename = "out.png")
    bg = ColorLayer(RGBA(0.5, 0.5, 0.5, 1); ArrayType = ArrayType)
    res = (1080, 1920)

    if transform_type == :check
        lolli = LolliPerson(height; ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)
        run!(lolli)
        write_image([bg, lolli]; filename = filename)
    elseif transform_type == :check_video
        lolli = LolliPerson(height; ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)
        video_out = open_video(res; framerate = 30, filename = "out.mp4")
        for i = 1:num_frames
            run!(lolli)
            write_video!(video_out, [bg, lolli])
        end

        close_video(video_out)
    elseif transform_type == :eye_roll
        eye_location = fi("eye_location", (0.0, 0.0))
        eye_operator = simple_eyes(location = eye_location, height = height)
        lolli = LolliPerson(height; eye_fum = eye_operator,
                            ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)

        video_out = open_video(res; framerate = 30, filename = "out.mp4")
        for i = 1:num_frames
            angle = 2*pi*i/num_frames
            radius = i*height*0.5/num_frames
            location = (radius*sin(angle), radius*cos(angle))
            set!(eye_location, location)

            run!(lolli)
            write_video!(video_out, [bg, lolli])
            reset!(lolli)
            reset!(bg)
        end

        close_video(video_out)

    elseif transform_type == :brow
        eye_operator = simple_eyes(brow_height = brow_height,
                                   show_brows = true,
                                   height = height)
        lolli = LolliPerson(height; eye_fum = eye_operator,
                            ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)
        run!(lolli)
        write_image([bg, lolli]; filename = filename)
    elseif transform_type == :blink
        brow_height = fi("brow_height", 1.0)
        show_brows = fi("show_brows", false)
        eye_operator = simple_eyes(brow_height = brow_height,
                                   show_brows = show_brows,
                                   height = height)
        lolli = LolliPerson(height; eye_fum = eye_operator,
                            ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)

        video_out = open_video(res; framerate = 30, filename = "out.mp4")
        for i = 1:num_frames
            blink!(lolli, i, 1, num_frames)

            run!(lolli)
            write_video!(video_out, [bg, lolli])
            reset!(lolli)
            reset!(bg)
        end

        close_video(video_out)
    elseif transform_type == :lean
        lean_angle = fi("lean_angle", 0)
        lean_velocity = fi("lean_velocity", 0.0)
        head_fo = fo(Fable.lean_head(foot_position = (height*0.5,0.0),
                                     head_radius = height*0.25,
                                     lean_velocity = lean_velocity,
                                     lean_angle = lean_angle))
        body_fo = fo(Fable.lean_body(height = height,
                                     foot_position = (height*0.5,0.0),
                                     lean_velocity = lean_velocity,
                                     lean_angle = lean_angle))
        lolli = LolliPerson(height; 
                            ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations,
                            head_smears = [head_fo],
                            body_smears = [body_fo])

        video_out = open_video(res; framerate = 30, filename = "out.mp4")
        for i = 1:num_frames
            new_angle = 0.25*pi*sin(2*pi*i/num_frames)
            set!(lean_velocity, abs(value(lean_angle) - new_angle))
            set!(lean_angle, new_angle)

            run!(lolli)
            write_video!(video_out, [bg, lolli])
            reset!(lolli)
            reset!(bg)
        end

        close_video(video_out)
    end

end

@info("Created Function: function lolli_example(num_particles, num_iterations;
                       height = 2.0, brow_height = 0.5,
                       ArrayType = Array, num_frames = 10,
                       transform_type = :check, filename = 'out.png')\n"*
      "transform_type can be {:check, :check_video,
                       :eye_roll, :brow, :blink, :lean}")
