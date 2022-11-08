using Fae, Images

function main(num_particles, num_iterations; AT = Array, FT = Float32)

    res = (1080, 1920)

    bounds = [-4.5 4.5; -8 8]*0.15

    flayer = FractalLayer(res; AT = AT, logscale = false)
    clayer = ColorLayer(RGB(0.5, 0.5, 0.5), res; AT = AT)

    square = define_rectangle([0.0,0.0], pi/4, 1.0, 1.0, RGB(1,0,1); AT = AT)

    fractal_flame!(flayer, square, num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)

    filename = "out.png"

    write_image([clayer, flayer], filename)
    #write_image([flayer], filename)
end
