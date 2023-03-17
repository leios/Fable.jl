using Fae, Images

function lolli_example(num_particles, num_iterations;
                       height = 2.0, brow_height = 0.5,
                       ArrayType = Array, num_frames = 10,
                       transform_type = :check,
                       diagnostic = false, filename = "out.png")
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
                            head_fis = [eye_location],
                            ArrayType = ArrayType,
                            num_particles = num_particles,
                            num_iterations = num_iterations)

        video_out = open_video(res; framerate = 30, filename = "out.mp4")
        for i = 1:num_frames
            angle = 2*pi*i/num_frames
            radius = i*height*0.5/num_frames
            location = (radius*sin(angle), radius*cos(angle))
            eye_location = set(eye_location, location)
            update_fis!(lolli; head_fis = [eye_location])

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
                            head_fis = [brow_height, show_brows],
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

    end

    return lolli

end
