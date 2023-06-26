using Fable, Images

function layering_example(num_particles, num_iterations; ArrayType = Array)

    world_size = (9*0.15, 16*0.15)
    ppu = 1920/world_size[2]

    square = define_rectangle(position = [0.0,0.0],
                              rotation = pi/4,
                              color = RGBA(1,0,1))
    flayer = FractalLayer(; ArrayType = ArrayType, H = square,
                          world_size = world_size, ppu = ppu,
                          num_particles = num_particles,
                          num_iterations = num_iterations)
    clayer = ColorLayer(RGB(0.5, 0.5, 0.5); world_size = world_size, ppu = ppu,
                        ArrayType = ArrayType)

    layers = [clayer, flayer]

    run!(layers)

    write_image(layers; filename = "out.png")
end

@info("Created Function: layering_example(num_particles, num_iterations;
                                         ArrayType = Array)")

