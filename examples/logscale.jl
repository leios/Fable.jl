using Fable

function logscale_example(num_particles, num_iterations; ArrayType = Array)

    world_size = (9*0.15, 16*0.15)
    ppu = 1920/world_size[2]

    circle = create_circle(chosen_fx = :naive_disk, color = Shaders.white)

    flayer = FableLayer(; ArrayType = ArrayType, H = circle,
                          world_size = world_size, ppu = ppu,
                          num_particles = num_particles,
                          num_iterations = num_iterations,
                          logscale = true, overlay = false)

    run!(flayer)

    #write_image(flayer; filename = "out.png")
    return write_image(flayer)
end

@info("Created Function: logscale_example(num_particles, num_iterations;
                                         ArrayType = Array)")

