using Fae

function main(num_particles, num_iterations; ArrayType = Array)

    circle = define_circle()

    outline = Outline()

    fl = FractalLayer(; H1 = circle, ArrayType = ArrayType,
                        postprocessing_steps = [outline])

    run!(fl)
    write_image(fl; filename = "out.png")
end
