using Fae, Images

function main(num_particles, num_iterations, ArrayType; dark = true)
    FloatType = Float32

    bounds = [-4.5 4.5; -8 8]*0.15
    res = (1080, 1920)

    pos = [0.0, 0.0]

    H = define_circle(pos, 1.0, [1.0, 1.0, 1.0])

    layer = FractalLayer(res; logscale = false, H_1 = H,
                         num_particles = num_particles,
                         num_iterations = num_iterations,
                         ArrayType = ArrayType, FloatType = FloatType)

    run!(layer, bounds)

    filename = "out.png"
    write_image(layer; filename = filename)
end
