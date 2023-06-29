using Fable, Images

# num_particles is the number of points being tracked by the chaos game
# num_iterations is the number of times each point moves in space
# ArrayType dictates what hardware you run this code on:
#     CuArray for NVIDIA GPUs
#     ROCArray for AMD GPUs
#     Array for parallel CPU 
function square_example(num_particles, num_iterations;
                        ArrayType = Array,
                        dark = true,
                        transform_type = :standard,
                        filename = "out.png")
    # Physical space location. 
    world_size = (9*0.15, 16*0.15)

    # Pixels per unit space
    # The aspect ratio is 16x9, so if we want 1920x1080, we can say we want...
    ppu = 1920/world_size[2]

    colors = [[1.0, 0.25, 0.25,1],
              [0.25, 1.0, 0.25, 1],
              [0.25, 0.25, 1.0, 1],
              [1.0, 0.25, 1.0, 1]]

    rot_fi = fi("rotation", 0.0)
    H = define_square(; position = [0.0, 0.0], rotation = rot_fi,
                        color = colors)
    swirl_operator = fo(Flames.swirl)
    H_post = nothing
    if transform_type == :outer_swirl
        H_post = Hutchinson(swirl_operator)
    elseif transform_type == :inner_swirl
        H = fee(Hutchinson, fo([H, swirl_operator]))
    end

    layer = FractalLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = world_size, ppu = ppu,
                         H = H, H_post = H_post,
                         num_particles = num_particles,
                         num_iterations = num_iterations)
    run!(layer)

    write_image(layer; filename = filename)
end

@info("Created Function: square_example(num_particles, num_iterations;
                                       ArrayType = Array,
                                       transform_type = :standard,
                                       filename = 'out.png')\n"*
      "transform_type can be {:standard, :inner_swirl, :outer_swirl}")
