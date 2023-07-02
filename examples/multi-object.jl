using Fable, Images

function multi_example(num_particles, num_iterations;
                       ArrayType = Array, filename = "out.png")
    world_size = (9*0.15, 16*0.15)

    ppu = 1920/world_size[2]

    square = define_square(; position = [-0.25, 0.0], scale = 0.25,
                             color = Shaders.blue)
    circle = define_circle(; position = [0.25, 0.0], radius = 0.25,
                             color = Shaders.red)

    final_H = Hutchinson([square, circle])

    layer = FractalLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = world_size, ppu = ppu,
                         H = final_H, num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)

    write_image(layer; filename = filename)
end

@info("Created Function: multi_example(num_particles, num_iterations;
                                       ArrayType = Array,
                                       filename = 'out.png')\n")
