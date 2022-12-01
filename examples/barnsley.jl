using Fae

scale_and_translate = @fo function scale_and_translate(x, y;
                                                       translation = (0,0),
                                                       scale = 1)
    x = scale*x + translation[2]
    y = scale*y + translation[1]
end

function main(num_particles, num_iterations; ArrayType = Array)
    FloatType = Float32

    bounds = [0 10; -8 8]
    res = (1080, 1920)

    layer = FractalLayer(res; ArrayType = ArrayType, FloatType = FloatType,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    pos = [0, 0.]
    color = [1., 1, 1, 1]
    radius = 1

    color_1 = [1.,1,1,1]
    color_2 = [1.,0,0,1]
    color_3 = [0.,1,0,1]
    color_4 = [0.,0,1,1]

    H = define_barnsley(; color = [color_1, color_2, color_3, color_4],
                          diagnostic=true, tilt = -0.04)
    H.prob_set = (0.01, 0.5, 0.245, 0.245)

    fo_1 = scale_and_translate(prob = 0.5, color = Shaders.previous,
                               translation = (0.5, 0.5), scale = 0.5)
    fo_2 = FractalOperator(Flames.identity, Shaders.magenta, 0.5)

    H2 = fee(Hutchinson, [fo_1, fo_2]; name = "2", final = true)

    layer.H1 = H
    layer.H2 = H2

    run!(layer, bounds)

    @time write_image([layer], filename = "out.png")
end
