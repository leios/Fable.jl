using Fae, Images, CUDA

# num_particles is the number of points being tracked by the chaos game
# num_iterations is the number of times each point moves in space
# AT is the ArrayType. CuArray for GPU. Array for parallel CPU 
function main(num_particles, num_iterations, AT; dark = true)
    FT = Float32

    # Physical space location. 
    bounds = [-4.5 4.5; -8 8]*0.15

    # Pixel grid
    res = (1080, 1920)

    # parameters for initial square
    pos = [0.0, 0.0]
    rotation = pi/4
    scale_x = 1.0
    scale_y = 1.0

    if dark
        colors = [[1.0, 0.25, 0.25,1],
                  [0.25, 1.0, 0.25, 1],
                  [0.25, 0.25, 1.0, 1],
                  [1.0, 0.25, 1.0, 1]]
    else
        colors = [[1.0, 0, 0,1],
                 [0, 1.0, 0, 1],
                 [0, 0, 1.0, 1],
                 [1.0, 0, 1.0, 1]]
    end

    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, colors; AT = AT)
    H2 = Hutchinson([Flames.swirl],
                    [Fae.Colors.previous],
                    (1.0,);
                    diagnostic = true, AT = AT, name = "2", final = true)
    #final_H = fee([H, H2])

    pix = Pixels(res; AT = AT, logscale = false, FT = FT)

    Fae.fractal_flame!(pix, H, H2, num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT)

    filename = "out.png"
    write_image([pix], filename)
end
