using Fae, Images

function clip_example(num_particles, num_iterations; ArrayType = Array)

    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    clip = Clip(; threshold = 0.5, color = RGBA(1, 1, 0, 1))

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [clip])

    run!(fl)
    write_image(fl; filename = "clip_out.png")
end

function identity_example(num_particles, num_iterations, ArrayType = Array)
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    identity = Identity()

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [identity])

    run!(fl)
    write_image(fl; filename = "identity_out.png")
end

function blur_example(num_particles, num_iterations; ArrayType = Array)
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    blur = Blur(; filter_size = 5)

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [blur])

    run!(fl)
    write_image(fl; filename = "blur_out.png")
end

function sobel_example(num_particles, num_iterations; ArrayType = Array)
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    sobel = Sobel()

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [sobel])

    run!(fl)
    write_image(fl; filename = "sobel_out.png")
end

function outline_example(num_particles, num_iterations; ArrayType = Array)
    circle = define_circle(; radius = 0.1, color = [1, 0, 1, 1])

    outline = Outline()

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [outline])

    run!(fl)
    write_image(fl; filename = "outline_out.png")
end

