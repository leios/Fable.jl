using Fae, Images

# num_particles is the number of points being tracked by the chaos game
# num_iterations is the number of times each point moves in space
# ArrayType dictates what hardware you run this code on:
#     CuArray for NVIDIA GPUs
#     ROCArray for AMD GPUs
#     Array for parallel CPU 
function square_example(num_particles, num_iterations;
                        ArrayType = Array, dark = true)
    FloatType = Float32

    # Physical space location. 
    world_size = (9*0.15, 16*0.15)

    # Pixels per unit space
    # The aspect ratio is 16x9, so if we want 1920x1080, we can say we want...
    ppu = 1920/world_size[2]

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

    H = define_square(; position = [0.0, 0.0], rotation = pi/4,  color = colors)
    H2 = Hutchinson([Flames.swirl],
                    [Shaders.previous],
                    (1.0,);
                    diagnostic = true, name = "2", final = true)

    # To combine a different way, use the final_H defined here
    # final_H = fee(Hutchinson, [H, H2])

    layer = FractalLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = world_size, ppu = ppu,
                         FloatType = FloatType, H1 = H, H2 = H2,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)

    write_image(layer; filename = "out.png")
end
