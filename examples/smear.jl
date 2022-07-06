using Fae

function main(num_particles, num_iterations, total_frames, AT)
    FT = Float32

    res = (1080, 1920)
    bounds = [-4.5 4.5; -8 8]

    radius = 1.0
    pos = [-2.0, -2.0]

    ball = define_circle(pos, radius, (1,1,1); AT = AT)

    object_position = fi("object_position", pos)
    previous_position = fi("previous_position", pos)
    previous_velocity = fi("previous_velocity", (0,0))
    factor = fi("factor", 1)

    fis = [object_position, previous_position, previous_velocity, factor]
    smear = Smears.simple_smear(factor = factor,
                                object_position = object_position,
                                previous_position = previous_position,
                                previous_velocity = previous_velocity)

    smear_transform = fee([FractalOperator(smear)], fis; name = "smear",
                          final = true, diagnostic = true)

    pix = Pixels(res; AT = AT, logscale = false, FT = FT)

    for i = 1:total_frames

        radius = 1.0
        pos = [-2.0+4*(i-1)/total_frames,
               -2.0+4*(i-1)/total_frames]

        update_circle!(ball, pos, radius)

        previous_position = set(previous_position, object_position.val)
        object_position = set(object_position, pos)

        update_fis!(smear_transform, [object_position, 
                                      previous_position,
                                      previous_velocity,
                                      factor])

        println(smear_transform.symbols)
        #println(smear_transform)

        filename = "check"*lpad(i,5,"0")*".png"

        fractal_flame!(pix, ball, smear_transform, num_particles,
                       num_iterations, bounds, res;
                       AT = AT, FT = FT)

        write_image([pix], filename)

        previous_velocity = set(previous_velocity, pos .- previous_position.val)
        zero!(pix)
    end

end
