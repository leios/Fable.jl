using Fae, Images

function main(num_particles, num_iterations; ArrayType = Array)

    res = (1080, 1920)

    bounds = [-4.5 4.5; -8 8]*0.15

    square = define_rectangle(position = [0.0,0.0],
                              rotation = pi/4,
                              color = RGBA(1,0,1))
    flayer = FractalLayer(res; ArrayType = ArrayType, H1 = square,
                          num_particles = num_particles,
                          num_iterations = num_iterations)
    clayer = ColorLayer(RGB(0.5, 0.5, 0.5), res; ArrayType = ArrayType)

    run!(flayer, bounds)

    write_image([clayer, flayer]; filename = "out.png")
end
