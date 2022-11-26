using Fae, Images

# num_particles is the number of points being tracked by the chaos game
# num_iterations is the number of times each point moves in space
# ArrayType dictates what hardware you run this code on:
#     CuArray for NVIDIA GPUs
#     ROCArray for AMD GPUs
#     Array for parallel CPU 
function main(num_particles, num_iterations, ArrayType; dark = true)
    FloatType = Float32

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

    H = define_rectangle(pos, rotation, scale_x, scale_y, colors)
    H2 = Hutchinson([Flames.swirl],
                    [Fae.Colors.previous],
                    (1.0,);
                    diagnostic = true, name = "2", final = true)

    # To combine a different way, use the final_H defined here
    # final_H = fee([H, H2])

    layer = FractalLayer(res; ArrayType = ArrayType, logscale = false,
                         FloatType = FloatType, H1 = H, H2 = H2,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer, bounds)

    write_image(layer; filename = "out.png")
end
