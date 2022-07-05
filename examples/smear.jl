using Fae

function main(num_particles, num_iterations, total_frames, AT)
    FT = Float32

    res = (1080, 1920)
    bounds = [-4.5 4.5; -8 8]

    radius = 1.0
    pos = [-2.0, -2.0]

    ball = define_circle(pos, radius, (1,1,1); AT = AT)

    #println(ball)

    pix = Pixels(res; AT = AT, logscale = false, FT = FT)

    for i = 1:total_frames

        radius = 1.0
        pos = [-2.0+4*(i-1)/total_frames,
               -2.0+4*(i-1)/total_frames]

        update_circle!(ball, pos, radius)

        filename = "check"*lpad(i,5,"0")*".png"

        fractal_flame!(pix, ball, num_particles, num_iterations, bounds, res;
                       AT = AT, FT = FT)

        write_image([pix], filename)

        zero!(pix)
    end

end
