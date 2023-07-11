using Fable, Images

function quick_circle(num_particles, num_iterations; ArrayType = Array,
                      filename = "out.png")
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    fl = FractalLayer(; H = circle, ArrayType = ArrayType)

    run!(fl)
    write_image(fl; filename = filename)
end

function clip_example(num_particles, num_iterations; ArrayType = Array,
                      filename = "clip_out.png")

    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    clip = Clip(; threshold = 0.5, color = RGBA(1, 1, 0, 1))

    fl = FractalLayer(; H = circle, ArrayType = ArrayType,
                        postprocessing_steps = [clip])

    run!(fl)
    write_image(fl; filename = filename)
end

function identity_example(num_particles, num_iterations; ArrayType = Array,
                          filename = "identity_out.png")
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    identity = Identity()

    fl = FractalLayer(; H = circle, ArrayType = ArrayType,
                        postprocessing_steps = [identity])

    run!(fl)
    write_image(fl; filename = filename)
end

function blur_example(num_particles, num_iterations; ArrayType = Array,
                      filter_size = 3, filename = "blur_out.png")
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    blur = Blur(; filter_size = filter_size)

    fl = FractalLayer(; H = circle, ArrayType = ArrayType,
                        postprocessing_steps = [blur])

    run!(fl)
    write_image(fl; filename = filename)
end

function sobel_example(num_particles, num_iterations; ArrayType = Array,
                       filename = "sobel_out.png")
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    sobel = Sobel()

    fl = FractalLayer(; H = circle, ArrayType = ArrayType,
                        postprocessing_steps = [sobel])

    run!(fl)
    write_image(fl; filename = filename)
end

function outline_example(num_particles, num_iterations; ArrayType = Array,
                         filename = "outline_out.png", linewidth = 1,
                         object_outline = false)
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    outline = Outline(; linewidth = linewidth, object_outline = object_outline)

    fl = FractalLayer(; H = circle, ArrayType = ArrayType,
                        postprocessing_steps = [outline])

    run!(fl)
    write_image(fl; filename = filename)
end

@info("Created Functions: quick_circle(num_particles, num_iterations;
                                      ArrayType = Array, filename = 'out.png')
                         clip_example(num_particles, num_iterations;
                                      ArrayType = Array,
                                      filename = 'clip_out.png')
                         identity_example(num_particles, num_iterations;
                                          ArrayType = Array,
                                          filename = 'identity_out.png')
                         blur_example(num_particles, num_iterations;
                                      ArrayType = Array, filter_size = 3,
                                      filename = 'blur_out.png')
                         sobel_example(num_particles, num_iterations;
                                       ArrayType = Array,
                                       filename = 'sobel_out.png')
                         outline_example(num_particles, num_iterations;
                                         ArrayType = Array,
                                         filename = 'outline_out.png',
                                         linewidth = 1,
                                         object_outline = false)")
