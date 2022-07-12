using Fae, CUDA

function main(num_particles, num_interactions, num_frames, AT;
              transform_type = :check)
    FT = Float32

    # Physical space location. 
    bounds = [-4.5 4.5; -8 8] * 0.5

    # Pixel grid
    res = (1080, 1920)
    bg = Pixels(res, (0.5, 0.5, 0.5, 1); AT = AT, logscale = false, FT = FT)
    pix = Pixels(res; AT = AT, logscale = false, FT = FT)

    lolli = Lolli.LolliPerson(2.0)

    if transform_type == :check
        Lolli.render_lolli!(pix, lolli,
                            num_particles, num_interactions, bounds, res;
                            AT = AT, FT = FT)

        filename = "out.png"
        write_image([bg, pix], filename)
    else
        video_out = open_video(res; framerate = 30, filename = "out.mp4",
                               encoder_options = (crf=23,
                                                  preset="medium",
                                                  pix_fmt="yuv420p"))
        for i = 1:num_frames

            Lolli.render_lolli!(pix, lolli,
                                num_particles, num_interactions, bounds, res;
                                AT = AT, FT = FT)

            write_video!(video_out, [bg, pix])
        end
        close_video(video_out)
    end
end
