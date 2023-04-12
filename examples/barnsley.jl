using Fae

scale_and_translate = @fum function scale_and_translate(y, x;
                                                       translation = (0.0,0.0),
                                                       scale = 1.0)
    x = scale*x + translation[2]
    y = scale*y + translation[1]
    return point(y,x)
end

function barnsley_example(num_particles, num_iterations;
                          ArrayType = Array,
                          filename = "out.png")

    pos = [0, 0.]
    radius = 1

    color_1 = [1.,1,1,1]
    color_2 = [1.,0,0,1]
    color_3 = [0.,1,0,1]
    color_4 = [0.,0,1,1]

    H = define_barnsley(; color = [color_1, color_2, color_3, color_4])
    #H.prob_set = (0.01, 0.5, 0.245, 0.245)

    fo_1 = fo(Flames.identity, Shaders.previous, 1)
    fo_2 = fo(scale_and_translate(translation = (0.5, 0.5), scale = 0.5),
              Shaders.magenta, 1)

    #H2 = fee(Hutchinson, (fo_1, fo_2))
    H2 = nothing

    layer = FractalLayer(; ArrayType = ArrayType,
                         world_size = (10, 16), position = (5, 0),
                         ppu = 1920/16, num_particles = num_particles,
                         num_iterations = num_iterations, H1 = H, H2 = H2)

    run!(layer)

    write_image([layer], filename = filename)
end
